import app from 'ags/gtk4/app';
import style from './style.scss';
import Manager from './appManager';

app.start({
  css: style,
  main() {
    app.get_monitors().map((m, i) => Manager(m, i));
  },
});
