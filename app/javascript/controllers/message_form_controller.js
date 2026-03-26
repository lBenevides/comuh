import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status", "submit"]
  static values = {
    communityId: Number,
    parentMessageId: String,
    targetList: String,
    mode: String,
    sendingMessage: String,
    successMessage: String,
    genericErrorMessage: String,
    timestampJustNow: String,
    sentimentPositiveLabel: String,
    sentimentNegativeLabel: String,
    sentimentNeutralLabel: String,
    repliesLabel: String,
    openThreadLabel: String,
    reactionLikeLabel: String,
    reactionLoveLabel: String,
    reactionInsightfulLabel: String,
    reactionReactAsLabel: String,
    reactionUsernamePlaceholder: String,
    reactionMissingReactionMessage: String,
    reactionMissingUsernameMessage: String,
    reactionSavingMessage: String,
    reactionSuccessMessage: String,
    reactionGenericErrorMessage: String
  }

  async submit(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const payload = {
      username: formData.get("username"),
      community_id: this.communityIdValue,
      content: formData.get("content"),
      parent_message_id: this.parentMessageIdValue || null
    }

    this.setBusyState(true, this.sendingMessageValue)

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
        throw new Error((body.errors || [body.error || this.genericErrorMessageValue]).join(", "))
      }

      this.injectMessage(body)
      this.formTarget.reset()
      this.setBusyState(false, this.successMessageValue)
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
    const sentimentLabel = sentimentScore > 0.2 ? this.sentimentPositiveLabelValue : sentimentScore < -0.2 ? this.sentimentNegativeLabelValue : this.sentimentNeutralLabelValue
    const sentimentClass = sentimentScore > 0.2 ? "sentiment-positive" : sentimentScore < -0.2 ? "sentiment-negative" : "sentiment-neutral"
    const replyCountLabel = this.repliesLabelValue.replace("%{count}", "0")
    const replyMeta = this.parentMessageIdValue ? replyCountLabel : '<a class="secondary-link" href="/messages/' + message.id + '">' + this.openThreadLabelValue + "</a>"
    const containerClass = this.parentMessageIdValue ? "thread-node" : ""

    return `
      <div class="${containerClass}" style="--depth: 1">
        <article class="message-card" id="message-${message.id}">
          <div class="message-card__topline">
            <div>
              <p class="message-card__author">${this.escapeHtml(message.user.username)}</p>
              <p class="message-card__timestamp">${this.timestampJustNowValue}</p>
            </div>
            <div class="message-card__badges">
              <span class="sentiment-pill ${sentimentClass}">
                ${sentimentLabel} · ${sentimentScore.toFixed(2)}
              </span>
            </div>
          </div>
          <p class="message-card__content">${this.escapeHtml(message.content)}</p>
          <div class="message-card__footer">
            <div
              class="reaction-row"
              data-controller="reaction"
              data-reaction-message-id-value="${message.id}"
              data-reaction-missing-reaction-message-value="${this.escapeHtml(this.reactionMissingReactionMessageValue)}"
              data-reaction-missing-username-message-value="${this.escapeHtml(this.reactionMissingUsernameMessageValue)}"
              data-reaction-saving-message-value="${this.escapeHtml(this.reactionSavingMessageValue)}"
              data-reaction-success-message-value="${this.escapeHtml(this.reactionSuccessMessageValue)}"
              data-reaction-generic-error-message-value="${this.escapeHtml(this.reactionGenericErrorMessageValue)}">
              ${[
                ["like", this.reactionLikeLabelValue],
                ["love", this.reactionLoveLabelValue],
                ["insightful", this.reactionInsightfulLabelValue]
              ].map(([reactionType, label]) => `
                <button type="button" class="reaction-button" data-action="click->reaction#react" data-reaction-reaction-type-param="${reactionType}">
                  <span>${this.escapeHtml(label)}</span>
                  <strong data-reaction-target="count" data-reaction-type="${reactionType}">0</strong>
                </button>
              `).join("")}
              <label class="reaction-user">
                <span>${this.escapeHtml(this.reactionReactAsLabelValue)}</span>
                <input type="text" placeholder="${this.escapeHtml(this.reactionUsernamePlaceholderValue)}" data-reaction-target="username">
              </label>
              <p class="reaction-status" data-reaction-target="status"></p>
            </div>
            <div class="message-card__meta">
              <span>${replyCountLabel}</span>
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
