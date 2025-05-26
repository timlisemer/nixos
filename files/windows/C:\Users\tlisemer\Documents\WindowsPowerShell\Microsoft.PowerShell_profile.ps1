Clear-Host

function wsl {
    cls
    if ($args.Count -eq 0) {
        & wsl.exe ~
    } elseif ($args.Count -eq 1 -and $args[0] -eq 'iocto') {
        & wsl.exe --cd ~/Coding/iocto
    } else {
        & wsl.exe $args
    }
}