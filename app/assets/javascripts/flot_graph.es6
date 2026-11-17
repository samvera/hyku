export class Graph {
  constructor(selector, data, options) {
    this.selector = selector
    this.data = data
    this.options = options;
  }

  // Drawn once, and not when empty: flot's pie plugin errors on a redraw or on no data
  activate() {
    if (this.plot || !this.data.length) return;
    this.plot = $.plot(this.selector, this.data, this.options);
  }
}
