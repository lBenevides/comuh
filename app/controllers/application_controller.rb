class ApplicationController < ActionController::Base
  before_action :set_locale

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def set_locale
    requested_locale = params[:locale].presence&.to_sym
    I18n.locale = I18n.available_locales.include?(requested_locale) ? requested_locale : I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
