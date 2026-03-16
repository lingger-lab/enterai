import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar", "slots", "timeSlotId", "reservationDatetime", "selectedDisplay"]

  connect() {
    this.currentMonth = new Date()
    this.currentMonth.setDate(1)
    this.availableDates = []
    this.selectedSlot = null
    this.renderCalendar()
    this.fetchAvailableDates()
  }

  async fetchAvailableDates() {
    const month = this.formatMonth(this.currentMonth)
    try {
      const response = await fetch(`/reservations/available_dates?month=${month}`)
      this.availableDates = await response.json()
      this.renderCalendar()
    } catch (e) {
      console.error("Failed to fetch dates:", e)
    }
  }

  async fetchSlots(dateStr) {
    try {
      const response = await fetch(`/reservations/available_slots?date=${dateStr}`)
      const slots = await response.json()
      this.renderSlots(dateStr, slots)
    } catch (e) {
      console.error("Failed to fetch slots:", e)
    }
  }

  renderCalendar() {
    const year = this.currentMonth.getFullYear()
    const month = this.currentMonth.getMonth()
    const firstDay = new Date(year, month, 1).getDay()
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    const monthNames = ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"]

    let html = `
      <div class="flex items-center justify-between mb-4">
        <button type="button" data-action="click->slot-picker#prevMonth" class="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        </button>
        <span class="text-base font-bold text-gray-900">${year}년 ${monthNames[month]}</span>
        <button type="button" data-action="click->slot-picker#nextMonth" class="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
        </button>
      </div>
      <table class="w-full text-center text-sm">
        <thead>
          <tr class="text-gray-500">
            <th class="py-2 text-red-400">일</th><th class="py-2">월</th><th class="py-2">화</th>
            <th class="py-2">수</th><th class="py-2">목</th><th class="py-2">금</th><th class="py-2 text-blue-400">토</th>
          </tr>
        </thead>
        <tbody>`

    let day = 1
    for (let row = 0; row < 6; row++) {
      html += "<tr>"
      for (let col = 0; col < 7; col++) {
        if ((row === 0 && col < firstDay) || day > daysInMonth) {
          html += '<td class="py-1.5"></td>'
        } else {
          const dateStr = `${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`
          const isAvailable = this.availableDates.includes(dateStr)
          const today = new Date()
          const isPast = new Date(dateStr) < new Date(today.getFullYear(), today.getMonth(), today.getDate())

          if (isAvailable && !isPast) {
            html += `<td class="py-1.5">
              <button type="button" data-action="click->slot-picker#selectDate"
                data-date="${dateStr}"
                class="w-9 h-9 rounded-full bg-indigo-100 text-indigo-700 font-semibold hover:bg-indigo-600 hover:text-white transition-colors">
                ${day}
              </button>
            </td>`
          } else {
            html += `<td class="py-1.5"><span class="w-9 h-9 inline-flex items-center justify-center text-gray-300">${day}</span></td>`
          }
          day++
        }
      }
      html += "</tr>"
      if (day > daysInMonth) break
    }

    html += "</tbody></table>"
    this.calendarTarget.innerHTML = html
  }

  renderSlots(dateStr, slots) {
    if (slots.length === 0) {
      this.slotsTarget.innerHTML = '<p class="text-sm text-gray-500 text-center py-4">이 날짜에 예약 가능한 시간이 없습니다.</p>'
      return
    }

    const dateParts = dateStr.split("-")
    const dateLabel = `${dateParts[1]}월 ${dateParts[2]}일`

    let html = `<p class="text-sm font-semibold text-gray-700 mb-3">${dateLabel} 예약 가능 시간</p><div class="grid grid-cols-2 gap-2">`
    for (const slot of slots) {
      html += `
        <button type="button" data-action="click->slot-picker#selectSlot"
          data-slot-id="${slot.id}" data-date="${dateStr}"
          data-start="${slot.start_time}" data-end="${slot.end_time}"
          data-coaching="${slot.coaching_type}"
          class="slot-btn p-3 border-2 border-gray-200 rounded-xl text-left hover:border-indigo-500 hover:bg-indigo-50 transition-all">
          <div class="text-sm font-bold text-gray-900">${slot.start_time} - ${slot.end_time}</div>
          <div class="text-xs text-gray-500">${slot.coaching_type}</div>
        </button>`
    }
    html += "</div>"
    this.slotsTarget.innerHTML = html
  }

  selectDate(event) {
    event.preventDefault()
    const dateStr = event.currentTarget.dataset.date
    this.fetchSlots(dateStr)

    // Highlight selected date
    this.calendarTarget.querySelectorAll("button[data-date]").forEach(btn => {
      btn.classList.remove("bg-indigo-600", "text-white")
      btn.classList.add("bg-indigo-100", "text-indigo-700")
    })
    event.currentTarget.classList.remove("bg-indigo-100", "text-indigo-700")
    event.currentTarget.classList.add("bg-indigo-600", "text-white")
  }

  selectSlot(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const slotId = btn.dataset.slotId
    const dateStr = btn.dataset.date
    const start = btn.dataset.start
    const end = btn.dataset.end
    const coaching = btn.dataset.coaching

    // Set hidden fields
    this.timeSlotIdTarget.value = slotId
    this.reservationDatetimeTarget.value = `${dateStr}T${start}`

    // Visual feedback
    this.slotsTarget.querySelectorAll(".slot-btn").forEach(b => {
      b.classList.remove("border-indigo-600", "bg-indigo-50", "ring-2", "ring-indigo-500")
      b.classList.add("border-gray-200")
    })
    btn.classList.remove("border-gray-200")
    btn.classList.add("border-indigo-600", "bg-indigo-50", "ring-2", "ring-indigo-500")

    // Update display
    if (this.hasSelectedDisplayTarget) {
      this.selectedDisplayTarget.textContent = `${dateStr} ${start} - ${end} (${coaching})`
      this.selectedDisplayTarget.classList.remove("hidden")
    }

    this.selectedSlot = { id: slotId, date: dateStr, start, end, coaching }

    // 코칭 형태 자동 세팅 (Step 5 — 슬롯에서 결정되므로 읽기 전용으로 표시)
    const coachingSelect = document.getElementById("reservation_coaching_type")
    if (coachingSelect) {
      coachingSelect.value = coaching
      coachingSelect.style.pointerEvents = "none"
      coachingSelect.style.opacity = "0.6"
    }
  }

  prevMonth(event) {
    event.preventDefault()
    this.currentMonth.setMonth(this.currentMonth.getMonth() - 1)
    this.slotsTarget.innerHTML = ""
    this.fetchAvailableDates()
  }

  nextMonth(event) {
    event.preventDefault()
    this.currentMonth.setMonth(this.currentMonth.getMonth() + 1)
    this.slotsTarget.innerHTML = ""
    this.fetchAvailableDates()
  }

  formatMonth(date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-01`
  }
}
