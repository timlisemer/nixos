import app from 'ags/gtk4/app';
import style from './style.scss';
import Bar from './widget/Bar';
import Overview from './widget/Overview';

app.start({
  css: style,
  main() {
    app.get_monitors().map(Overview);
    app.get_monitors().map(Bar);
  },
});
