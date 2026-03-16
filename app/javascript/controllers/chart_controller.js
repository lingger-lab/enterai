import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { type: String, data: Object, options: Object }

  async connect() {
    const { Chart, registerables } = await import("chart.js")
    Chart.register(...registerables)

    const canvas = this.element.querySelector("canvas")
    if (!canvas) return

    this.chart = new Chart(canvas, {
      type: this.typeValue,
      data: this.dataValue,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: this.typeValue !== "line" }
        },
        ...this.optionsValue
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
