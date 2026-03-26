import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "status", "username"]
  static values = {
    messageId: Number,
    missingReactionMessage: String,
    missingUsernameMessage: String,
    savingMessage: String,
    successMessage: String,
    genericErrorMessage: String
  }

  async react(event) {
    const reactionType = event.params.reactionType || event.currentTarget.dataset.reactionReactionTypeParam
    const username = this.usernameTarget.value.trim()

    if (!reactionType) {
      this.statusTarget.textContent = this.missingReactionMessageValue
      return
    }

    if (!username) {
      this.statusTarget.textContent = this.missingUsernameMessageValue
      return
    }

    this.statusTarget.textContent = this.savingMessageValue

    try {
      const response = await fetch("/api/v1/reactions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          message_id: this.messageIdValue,
          username,
          reaction_type: reactionType
        })
      })

      const body = await response.json()

      if (!response.ok) {
        throw new Error((body.errors || [body.error || this.genericErrorMessageValue]).join(", "))
      }

      this.updateCounts(body.reactions)
      this.statusTarget.textContent = this.successMessageValue
    } catch (error) {
      this.statusTarget.textContent = error.message
    }
  }

  updateCounts(reactions) {
    this.countTargets.forEach((target) => {
      const reactionType = target.dataset.reactionType
      target.textContent = reactions[reactionType] || 0
    })
  }
}
