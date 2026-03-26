import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status", "submit"]
  static values = {
    communityId: Number,
    parentMessageId: String,
    targetList: String,
    mode: String
  }

  async submit(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const payload = {
      username: formData.get("username"),
      community_id: this.communityIdValue,
      content: formData.get("content"),
      user_ip: formData.get("user_ip"),
      parent_message_id: this.parentMessageIdValue || null
    }

    this.setBusyState(true, "Sending...")

    try {
      const response = await fetch("/api/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify(payload)
      })

      const body = await response.json()

      if (!response.ok) {
        throw new Error((body.errors || [body.error || "Unable to send message."]).join(", "))
      }

      this.injectMessage(body)
      this.formTarget.reset()
      this.setBusyState(false, "Published.")
    } catch (error) {
      this.setBusyState(false, error.message)
    }
  }

  injectMessage(message) {
    const list = document.getElementById(this.targetListValue)
    if (!list) return

    const wrapper = document.createElement("div")
    wrapper.innerHTML = this.messageTemplate(message)

    if (this.modeValue === "append") {
      list.append(wrapper.firstElementChild)
    } else {
      list.prepend(wrapper.firstElementChild)
    }
  }

  messageTemplate(message) {
    const sentimentScore = Number(message.ai_sentiment_score || 0)
    const sentimentLabel = sentimentScore > 0.2 ? "Positive" : sentimentScore < -0.2 ? "Negative" : "Neutral"
    const sentimentClass = sentimentScore > 0.2 ? "sentiment-positive" : sentimentScore < -0.2 ? "sentiment-negative" : "sentiment-neutral"
    const replyMeta = this.parentMessageIdValue ? "0 replies" : '<a class="secondary-link" href="/messages/' + message.id + '">Open thread</a>'
    const containerClass = this.parentMessageIdValue ? "thread-node" : ""

    return `
      <div class="${containerClass}" style="--depth: 1">
        <article class="message-card" id="message-${message.id}">
          <div class="message-card__topline">
            <div>
              <p class="message-card__author">${this.escapeHtml(message.user.username)}</p>
              <p class="message-card__timestamp">just now</p>
            </div>
            <div class="message-card__badges">
              <span class="sentiment-pill ${sentimentClass}">
                ${sentimentLabel} · ${sentimentScore.toFixed(2)}
              </span>
            </div>
          </div>
          <p class="message-card__content">${this.escapeHtml(message.content)}</p>
          <div class="message-card__footer">
            <div class="reaction-row" data-controller="reaction" data-reaction-message-id-value="${message.id}">
              ${["like", "love", "insightful"].map((reactionType) => `
                <button type="button" class="reaction-button" data-action="click->reaction#react" data-reaction-type-param="${reactionType}">
                  <span>${reactionType.charAt(0).toUpperCase() + reactionType.slice(1)}</span>
                  <strong data-reaction-target="count" data-reaction-type="${reactionType}">0</strong>
                </button>
              `).join("")}
              <label class="reaction-user">
                <span>React as</span>
                <input type="text" placeholder="username" data-reaction-target="username">
              </label>
              <p class="reaction-status" data-reaction-target="status"></p>
            </div>
            <div class="message-card__meta">
              <span>0 replies</span>
              ${replyMeta}
            </div>
          </div>
        </article>
      </div>
    `
  }

  setBusyState(isBusy, message) {
    this.submitTarget.disabled = isBusy
    this.statusTarget.textContent = message
    this.statusTarget.dataset.state = isBusy ? "busy" : "idle"
  }

  escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }
}
