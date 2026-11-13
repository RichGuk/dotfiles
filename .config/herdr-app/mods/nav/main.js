// nav: ctrl-h/j/k/l between panes, as vim-tmux-navigator does with tmux. When
// the focused pane runs Neovim the key goes to it (its own splits use them);
// otherwise Herdr moves to the pane that way. Lives in a 0px sidebar block so
// it's always running; keys.json binds nav.left/down/up/right.

import { View, div } from "gpui-kit";
import { focused, panes, run, hc, nextCommand } from "herdr";

const DIRS = { left: "h", down: "j", up: "k", right: "l" };
const PASS = ["nvim", "vim"];

export default class Nav extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) {
        const dir = await nextCommand();
        if (!DIRS[dir]) continue;
        const f = focused();
        const pane = f?.pane && panes().find((p) => p.pane === f.pane);
        if (pane?.terminal && PASS.includes(pane.program?.key)) await hc(["keys", pane.terminal, `ctrl+${DIRS[dir]}`]).catch(() => null);
        else run("pane.go", { direction: dir });
      }
    });
  }

  render() {
    return div();
  }
}
