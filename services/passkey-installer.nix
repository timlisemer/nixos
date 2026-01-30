{
  config,
  pkgs,
  lib,
  hostName,
  ...
}: let
  # Only enable on homeassistant-yellow
  isEnabled = hostName == "homeassistant-yellow";

  # Python environment with all required packages
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      fastapi
      uvicorn
      webauthn
      pydantic
      cryptography
      aiofiles
    ]);

  # Self-signed certificate for HTTPS (WebAuthn requires secure context)
  selfSignedCert =
    pkgs.runCommand "passkey-installer-cert" {
      nativeBuildInputs = [pkgs.openssl];
    } ''
      mkdir -p $out
      openssl req -x509 -newkey rsa:4096 -keyout $out/key.pem -out $out/cert.pem \
        -days 3650 -nodes -subj "/CN=homeassistant-yellow.local"
    '';

  # The FastAPI application for passkey authentication
  installerApp = pkgs.writeText "passkey_installer.py" ''
    #!/usr/bin/env python3
    """
    Passkey-protected NixOS installer service.
    Provides WebAuthn authentication to securely distribute SSH keys.
    """
    import os
    import json
    import secrets
    import hashlib
    import time
    from pathlib import Path
    from typing import Optional

    from fastapi import FastAPI, HTTPException, Response
    from fastapi.responses import PlainTextResponse, HTMLResponse
    from pydantic import BaseModel
    import webauthn
    from webauthn.helpers import (
        bytes_to_base64url,
        base64url_to_bytes,
    )
    from webauthn.helpers.structs import (
        AuthenticatorSelectionCriteria,
        UserVerificationRequirement,
        ResidentKeyRequirement,
        PublicKeyCredentialDescriptor,
    )

    app = FastAPI(title="NixOS Passkey Installer")

    # Configuration
    RP_ID = os.environ.get("RP_ID", "homeassistant-yellow.local")
    RP_NAME = os.environ.get("RP_NAME", "NixOS Installer")
    RP_ORIGIN = os.environ.get("RP_ORIGIN", "https://homeassistant-yellow.local:8901")
    SSH_KEY_PATH = os.environ.get("SSH_KEY_PATH", "/run/secrets/installer_ssh_key")
    DATA_DIR = Path(os.environ.get("DATA_DIR", "/var/lib/passkey-installer"))

    # In-memory session storage (for simplicity)
    sessions: dict = {}
    # Registered credentials storage
    credentials_file = DATA_DIR / "credentials.json"


    def load_credentials() -> dict:
        if credentials_file.exists():
            return json.loads(credentials_file.read_text())
        return {}


    def save_credentials(creds: dict):
        credentials_file.parent.mkdir(parents=True, exist_ok=True)
        credentials_file.write_text(json.dumps(creds, indent=2))


    class RegistrationRequest(BaseModel):
        username: str


    class RegistrationResponse(BaseModel):
        credential: str
        client_data: str
        attestation: str


    class AuthCompleteRequest(BaseModel):
        session_id: str
        credential_id: str
        client_data: str
        authenticator_data: str
        signature: str
        user_handle: Optional[str] = None


    @app.get("/")
    async def root():
        return {"status": "ok", "service": "NixOS Passkey Installer"}


    @app.get("/install", response_class=PlainTextResponse)
    async def get_install_script():
        """Return the curl-able installation script."""
        script = """#!/usr/bin/env bash
    set -euo pipefail

    echo "=== NixOS Passkey Installation ==="
    echo ""

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root (use sudo or run from live USB as root)"
        exit 1
    fi

    # Install required tools if not present
    if ! command -v qrencode &>/dev/null; then
        echo "Installing qrencode..."
        nix-env -iA nixos.qrencode || nix profile install nixpkgs#qrencode
    fi

    if ! command -v jq &>/dev/null; then
        echo "Installing jq..."
        nix-env -iA nixos.jq || nix profile install nixpkgs#jq
    fi

    # Start authentication session
    echo "Starting authentication session..."
    SESSION_DATA=$(curl -s "http://homeassistant-yellow.local:8900/auth/begin")
    SESSION_ID=$(echo "$SESSION_DATA" | jq -r '.session_id')
    AUTH_URL=$(echo "$SESSION_DATA" | jq -r '.auth_url')

    if [[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]]; then
        echo "Error: Failed to start authentication session"
        echo "Response: $SESSION_DATA"
        exit 1
    fi

    echo ""
    echo "Scan this QR code with your phone to authenticate:"
    echo "(Use your camera app, then authenticate with Bitwarden passkey)"
    echo ""
    qrencode -t ANSIUTF8 "$AUTH_URL"
    echo ""
    echo "Or open this URL on your phone: $AUTH_URL"
    echo ""
    echo "Waiting for authentication (timeout: 5 minutes)..."

    # Poll for authentication completion
    for i in {1..300}; do
        STATUS=$(curl -s "http://homeassistant-yellow.local:8900/auth/status/$SESSION_ID")
        STATE=$(echo "$STATUS" | jq -r '.state')

        if [[ "$STATE" == "authenticated" ]]; then
            TOKEN=$(echo "$STATUS" | jq -r '.token')
            echo ""
            echo "Authentication successful!"
            break
        elif [[ "$STATE" == "failed" ]]; then
            echo ""
            echo "Authentication failed: $(echo "$STATUS" | jq -r '.error')"
            exit 1
        fi

        # Show progress every 10 seconds
        if (( i % 10 == 0 )); then
            echo -n "."
        fi
        sleep 1
    done

    if [[ "$STATE" != "authenticated" ]]; then
        echo ""
        echo "Authentication timed out"
        exit 1
    fi

    # Retrieve SSH key
    echo "Retrieving SSH key..."
    SSH_KEY=$(curl -s "http://homeassistant-yellow.local:8900/key/$TOKEN")

    if [[ -z "$SSH_KEY" || "$SSH_KEY" == *"error"* ]]; then
        echo "Error: Failed to retrieve SSH key"
        echo "Response: $SSH_KEY"
        exit 1
    fi

    # Set up SSH key for the live environment
    mkdir -p /root/.ssh
    echo "$SSH_KEY" > /root/.ssh/id_ed25519
    chmod 600 /root/.ssh/id_ed25519
    ssh-keygen -y -f /root/.ssh/id_ed25519 > /root/.ssh/id_ed25519.pub

    # Generate age key
    if command -v ssh-to-age &>/dev/null; then
        mkdir -p /root/.config/sops/age
        ssh-to-age -private-key -i /root/.ssh/id_ed25519 > /root/.config/sops/age/keys.txt
        chmod 600 /root/.config/sops/age/keys.txt
    fi

    echo ""
    echo "SSH key installed successfully!"
    echo ""
    echo "You can now proceed with NixOS installation:"
    echo ""
    echo "  1. Clone the repository:"
    echo "     git clone git@github.com:timlisemer/nixos.git /tmp/nixos"
    echo ""
    echo "  2. Run disko to partition disks (example for tim-laptop):"
    echo "     nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount /tmp/nixos/common/disko.nix --arg disks '[ \\"/dev/nvme0n1\\" ]'"
    echo ""
    echo "  3. Copy configuration:"
    echo "     mkdir -p /mnt/etc/nixos"
    echo "     cp -a /tmp/nixos/* /mnt/etc/nixos/"
    echo ""
    echo "  4. Set up keys for /mnt:"
    echo "     mkdir -p /mnt/home/tim/.ssh /mnt/home/tim/.config/sops/age /mnt/etc/ssh"
    echo "     cp /root/.ssh/id_ed25519* /mnt/home/tim/.ssh/"
    echo "     cp /root/.config/sops/age/keys.txt /mnt/home/tim/.config/sops/age/"
    echo "     cp /root/.ssh/id_ed25519 /mnt/etc/ssh/nixos_personal_sops_key"
    echo ""
    echo "  5. Install NixOS:"
    echo "     nixos-install --flake /mnt/etc/nixos#<hostname>"
    echo ""
    """
        return script


    @app.get("/auth/begin")
    async def auth_begin():
        """Start a WebAuthn authentication session."""
        credentials = load_credentials()

        if not credentials:
            raise HTTPException(
                status_code=400,
                detail="No passkeys registered. Please register a passkey first via /register/begin"
            )

        session_id = secrets.token_urlsafe(32)
        challenge = secrets.token_bytes(32)

        # Build list of allowed credentials
        allow_credentials = [
            PublicKeyCredentialDescriptor(id=base64url_to_bytes(cred_id))
            for cred_id in credentials.keys()
        ]

        options = webauthn.generate_authentication_options(
            rp_id=RP_ID,
            challenge=challenge,
            allow_credentials=allow_credentials,
            user_verification=UserVerificationRequirement.PREFERRED,
        )

        sessions[session_id] = {{
            "challenge": bytes_to_base64url(challenge),
            "state": "pending",
            "created": time.time(),
            "token": None,
        }}

        # Clean up old sessions (older than 10 minutes)
        current_time = time.time()
        expired = [sid for sid, sess in sessions.items() if current_time - sess["created"] > 600]
        for sid in expired:
            del sessions[sid]

        return {{
            "session_id": session_id,
            "auth_url": f"{{RP_ORIGIN}}/auth/verify?session={{session_id}}",
            "options": options.model_dump(),
        }}


    @app.get("/auth/verify", response_class=HTMLResponse)
    async def auth_verify_page(session: str):
        """Serve the WebAuthn authentication page for mobile devices."""
        if session not in sessions:
            return HTMLResponse("<h1>Invalid or expired session</h1>", status_code=400)

        sess = sessions[session]
        if sess["state"] != "pending":
            return HTMLResponse("<h1>Session already used</h1>", status_code=400)

        credentials = load_credentials()
        allow_credentials_json = json.dumps([
            {{"type": "public-key", "id": cred_id}}
            for cred_id in credentials.keys()
        ])

        html = f"""<!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>NixOS Installer Authentication</title>
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px; max-width: 500px; margin: 0 auto; }}
            h1 {{ color: #5277C3; }}
            button {{ background: #5277C3; color: white; border: none; padding: 15px 30px; font-size: 18px; border-radius: 8px; cursor: pointer; width: 100%; margin-top: 20px; }}
            button:disabled {{ background: #ccc; }}
            .status {{ padding: 15px; border-radius: 8px; margin-top: 20px; }}
            .success {{ background: #d4edda; color: #155724; }}
            .error {{ background: #f8d7da; color: #721c24; }}
            .info {{ background: #cce5ff; color: #004085; }}
        </style>
    </head>
    <body>
        <h1>NixOS Installer</h1>
        <p>Authenticate with your passkey to allow SSH key retrieval for NixOS installation.</p>

        <button id="authBtn" onclick="authenticate()">Authenticate with Passkey</button>

        <div id="status" class="status info" style="display:none;"></div>

        <script>
            const sessionId = "{session}";
            const rpId = "{RP_ID}";
            const challenge = "{sess['challenge']}";
            const allowCredentials = {allow_credentials_json};

            function base64urlToBuffer(base64url) {{
                const padding = '='.repeat((4 - base64url.length % 4) % 4);
                const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/') + padding;
                const binary = atob(base64);
                const bytes = new Uint8Array(binary.length);
                for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
                return bytes.buffer;
            }}

            function bufferToBase64url(buffer) {{
                const bytes = new Uint8Array(buffer);
                var binary = "";
                for (var i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
                return btoa(binary).replace(/\\+/g, "-").replace(/\\//g, "_").replace(/=/g, "");
            }}

            async function authenticate() {{
                const btn = document.getElementById('authBtn');
                const status = document.getElementById('status');

                btn.disabled = true;
                btn.textContent = 'Authenticating...';
                status.style.display = 'block';
                status.className = 'status info';
                status.textContent = 'Please use your passkey to authenticate...';

                try {{
                    const credential = await navigator.credentials.get({{
                        publicKey: {{
                            challenge: base64urlToBuffer(challenge),
                            rpId: rpId,
                            allowCredentials: allowCredentials.map(c => ({{
                                type: c.type,
                                id: base64urlToBuffer(c.id)
                            }})),
                            userVerification: 'preferred',
                            timeout: 60000
                        }}
                    }});

                    const response = await fetch('/auth/complete', {{
                        method: 'POST',
                        headers: {{ 'Content-Type': 'application/json' }},
                        body: JSON.stringify({{
                            session_id: sessionId,
                            credential_id: bufferToBase64url(credential.rawId),
                            client_data: bufferToBase64url(credential.response.clientDataJSON),
                            authenticator_data: bufferToBase64url(credential.response.authenticatorData),
                            signature: bufferToBase64url(credential.response.signature),
                            user_handle: credential.response.userHandle ? bufferToBase64url(credential.response.userHandle) : null
                        }})
                    }});

                    const result = await response.json();

                    if (result.success) {{
                        status.className = 'status success';
                        status.textContent = 'Authentication successful! You can close this page and return to your terminal.';
                        btn.textContent = 'Authenticated';
                    }} else {{
                        throw new Error(result.error || 'Authentication failed');
                    }}
                }} catch (err) {{
                    status.className = 'status error';
                    status.textContent = 'Error: ' + err.message;
                    btn.disabled = false;
                    btn.textContent = 'Try Again';
                }}
            }}
        </script>
    </body>
    </html>"""
        return HTMLResponse(html)


    @app.post("/auth/complete")
    async def auth_complete(request: AuthCompleteRequest):
        """Complete WebAuthn authentication."""
        if request.session_id not in sessions:
            raise HTTPException(status_code=400, detail="Invalid session")

        sess = sessions[request.session_id]
        if sess["state"] != "pending":
            raise HTTPException(status_code=400, detail="Session already used")

        credentials = load_credentials()
        if request.credential_id not in credentials:
            raise HTTPException(status_code=400, detail="Unknown credential")

        cred = credentials[request.credential_id]

        try:
            verification = webauthn.verify_authentication_response(
                credential={{
                    "id": request.credential_id,
                    "rawId": request.credential_id,
                    "response": {{
                        "clientDataJSON": request.client_data,
                        "authenticatorData": request.authenticator_data,
                        "signature": request.signature,
                    }},
                    "type": "public-key",
                    "authenticatorAttachment": "cross-platform",
                    "clientExtensionResults": {{}},
                }},
                expected_challenge=base64url_to_bytes(sess["challenge"]),
                expected_rp_id=RP_ID,
                expected_origin=RP_ORIGIN,
                credential_public_key=base64url_to_bytes(cred["public_key"]),
                credential_current_sign_count=cred.get("sign_count", 0),
            )

            # Update sign count
            cred["sign_count"] = verification.new_sign_count
            save_credentials(credentials)

            # Generate one-time token for key retrieval
            token = secrets.token_urlsafe(32)
            sess["state"] = "authenticated"
            sess["token"] = token

            return {{"success": True}}

        except Exception as e:
            sess["state"] = "failed"
            raise HTTPException(status_code=400, detail=str(e))


    @app.get("/auth/status/{{session_id}}")
    async def auth_status(session_id: str):
        """Check authentication status."""
        if session_id not in sessions:
            return {{"state": "invalid"}}

        sess = sessions[session_id]
        result = {{"state": sess["state"]}}

        if sess["state"] == "authenticated" and sess["token"]:
            result["token"] = sess["token"]

        return result


    @app.get("/key/{{token}}", response_class=PlainTextResponse)
    async def get_key(token: str):
        """Retrieve SSH key with one-time token."""
        # Find session with this token
        for session_id, sess in sessions.items():
            if sess.get("token") == token and sess["state"] == "authenticated":
                # Invalidate token (one-time use)
                sess["token"] = None
                sess["state"] = "used"

                # Read and return SSH key
                try:
                    with open(SSH_KEY_PATH, "r") as f:
                        return f.read()
                except FileNotFoundError:
                    raise HTTPException(status_code=500, detail="SSH key not configured")

        raise HTTPException(status_code=403, detail="Invalid or expired token")


    # === Registration endpoints (run once to set up passkey) ===

    @app.get("/register/begin")
    async def register_begin(username: str = "admin"):
        """Start passkey registration (run once to set up)."""
        user_id = hashlib.sha256(username.encode()).digest()

        options = webauthn.generate_registration_options(
            rp_id=RP_ID,
            rp_name=RP_NAME,
            user_id=user_id,
            user_name=username,
            user_display_name=username,
            authenticator_selection=AuthenticatorSelectionCriteria(
                resident_key=ResidentKeyRequirement.PREFERRED,
                user_verification=UserVerificationRequirement.PREFERRED,
            ),
        )

        session_id = secrets.token_urlsafe(32)
        sessions[session_id] = {{
            "challenge": bytes_to_base64url(options.challenge),
            "user_id": bytes_to_base64url(user_id),
            "state": "registering",
            "created": time.time(),
        }}

        return {{
            "session_id": session_id,
            "options": options.model_dump(),
            "register_url": f"{{RP_ORIGIN}}/register/page?session={{session_id}}",
        }}


    @app.get("/register/page", response_class=HTMLResponse)
    async def register_page(session: str):
        """Registration page for mobile devices."""
        if session not in sessions or sessions[session]["state"] != "registering":
            return HTMLResponse("<h1>Invalid or expired session</h1>", status_code=400)

        sess = sessions[session]

        html = f"""<!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Register Passkey - NixOS Installer</title>
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px; max-width: 500px; margin: 0 auto; }}
            h1 {{ color: #5277C3; }}
            button {{ background: #5277C3; color: white; border: none; padding: 15px 30px; font-size: 18px; border-radius: 8px; cursor: pointer; width: 100%; margin-top: 20px; }}
            button:disabled {{ background: #ccc; }}
            .status {{ padding: 15px; border-radius: 8px; margin-top: 20px; }}
            .success {{ background: #d4edda; color: #155724; }}
            .error {{ background: #f8d7da; color: #721c24; }}
            .info {{ background: #cce5ff; color: #004085; }}
        </style>
    </head>
    <body>
        <h1>Register Passkey</h1>
        <p>Register a passkey to enable secure NixOS installations.</p>

        <button id="regBtn" onclick="register()">Register Passkey</button>

        <div id="status" class="status info" style="display:none;"></div>

        <script>
            const sessionId = "{session}";
            const rpId = "{RP_ID}";
            const rpName = "{RP_NAME}";
            const challenge = "{sess['challenge']}";
            const userId = "{sess['user_id']}";

            function base64urlToBuffer(base64url) {{
                const padding = '='.repeat((4 - base64url.length % 4) % 4);
                const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/') + padding;
                const binary = atob(base64);
                const bytes = new Uint8Array(binary.length);
                for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
                return bytes.buffer;
            }}

            function bufferToBase64url(buffer) {{
                const bytes = new Uint8Array(buffer);
                var binary = "";
                for (var i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
                return btoa(binary).replace(/\\+/g, "-").replace(/\\//g, "_").replace(/=/g, "");
            }}

            async function register() {{
                const btn = document.getElementById('regBtn');
                const status = document.getElementById('status');

                btn.disabled = true;
                btn.textContent = 'Registering...';
                status.style.display = 'block';
                status.className = 'status info';
                status.textContent = 'Follow the prompts to register your passkey...';

                try {{
                    const credential = await navigator.credentials.create({{
                        publicKey: {{
                            challenge: base64urlToBuffer(challenge),
                            rp: {{ id: rpId, name: rpName }},
                            user: {{
                                id: base64urlToBuffer(userId),
                                name: "admin",
                                displayName: "NixOS Installer Admin"
                            }},
                            pubKeyCredParams: [
                                {{ type: "public-key", alg: -7 }},
                                {{ type: "public-key", alg: -257 }}
                            ],
                            authenticatorSelection: {{
                                residentKey: "preferred",
                                userVerification: "preferred"
                            }},
                            timeout: 60000
                        }}
                    }});

                    const response = await fetch('/register/complete', {{
                        method: 'POST',
                        headers: {{ 'Content-Type': 'application/json' }},
                        body: JSON.stringify({{
                            session_id: sessionId,
                            credential_id: bufferToBase64url(credential.rawId),
                            client_data: bufferToBase64url(credential.response.clientDataJSON),
                            attestation: bufferToBase64url(credential.response.attestationObject)
                        }})
                    }});

                    const result = await response.json();

                    if (result.success) {{
                        status.className = 'status success';
                        status.textContent = 'Passkey registered successfully! You can now use it to authenticate NixOS installations.';
                        btn.textContent = 'Registered';
                    }} else {{
                        throw new Error(result.error || 'Registration failed');
                    }}
                }} catch (err) {{
                    status.className = 'status error';
                    status.textContent = 'Error: ' + err.message;
                    btn.disabled = false;
                    btn.textContent = 'Try Again';
                }}
            }}
        </script>
    </body>
    </html>"""
        return HTMLResponse(html)


    class RegisterCompleteRequest(BaseModel):
        session_id: str
        credential_id: str
        client_data: str
        attestation: str


    @app.post("/register/complete")
    async def register_complete(request: RegisterCompleteRequest):
        """Complete passkey registration."""
        if request.session_id not in sessions:
            raise HTTPException(status_code=400, detail="Invalid session")

        sess = sessions[request.session_id]
        if sess["state"] != "registering":
            raise HTTPException(status_code=400, detail="Invalid session state")

        try:
            verification = webauthn.verify_registration_response(
                credential={{
                    "id": request.credential_id,
                    "rawId": request.credential_id,
                    "response": {{
                        "clientDataJSON": request.client_data,
                        "attestationObject": request.attestation,
                    }},
                    "type": "public-key",
                    "clientExtensionResults": {{}},
                    "authenticatorAttachment": "cross-platform",
                }},
                expected_challenge=base64url_to_bytes(sess["challenge"]),
                expected_rp_id=RP_ID,
                expected_origin=RP_ORIGIN,
            )

            # Save credential
            credentials = load_credentials()
            credentials[request.credential_id] = {{
                "public_key": bytes_to_base64url(verification.credential_public_key),
                "sign_count": verification.sign_count,
                "user_id": sess["user_id"],
            }}
            save_credentials(credentials)

            del sessions[request.session_id]
            return {{"success": True}}

        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))


    if __name__ == "__main__":
        import uvicorn
        uvicorn.run(app, host="0.0.0.0", port=8902)
  '';
in {
  config = lib.mkIf isEnabled {
    # SSH key secret for distribution
    sops.secrets.installer_ssh_key = {
      sopsFile = ../secrets/secrets.yaml;
      mode = "0400";
    };

    # State directory for passkey credentials
    systemd.tmpfiles.rules = [
      "d /var/lib/passkey-installer 0750 root root -"
    ];

    # Python passkey service (HTTPS on port 8901 with self-signed cert for WebAuthn)
    systemd.services.passkey-installer = {
      description = "Passkey-protected NixOS installer service (HTTPS)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        RP_ID = "homeassistant-yellow.local";
        RP_NAME = "NixOS Installer";
        RP_ORIGIN = "https://homeassistant-yellow.local:8901";
        SSH_KEY_PATH = "/run/secrets/installer_ssh_key";
        DATA_DIR = "/var/lib/passkey-installer";
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pythonEnv}/bin/uvicorn passkey_installer:app --host 0.0.0.0 --port 8901 --ssl-keyfile ${selfSignedCert}/key.pem --ssl-certfile ${selfSignedCert}/cert.pem";
        WorkingDirectory = "/var/lib/passkey-installer";
        Restart = "always";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = ["/var/lib/passkey-installer"];
      };

      preStart = ''
        cp ${installerApp} /var/lib/passkey-installer/passkey_installer.py
      '';
    };

    # Simple HTTP server for the install script (port 8900)
    # This serves the curl-able script without HTTPS for ease of use
    systemd.services.passkey-installer-http = {
      description = "HTTP endpoint for install script";
      after = ["passkey-installer.service"];
      wants = ["passkey-installer.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pythonEnv}/bin/uvicorn passkey_installer:app --host 0.0.0.0 --port 8900";
        WorkingDirectory = "/var/lib/passkey-installer";
        Restart = "always";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = ["/var/lib/passkey-installer"];
      };
    };

    # Firewall rules
    networking.firewall.allowedTCPPorts = [
      8900 # HTTP for install script
      8901 # HTTPS for WebAuthn
    ];

    environment.systemPackages = [pythonEnv];
  };
}
