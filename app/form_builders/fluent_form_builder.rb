class FluentFormBuilder < ActionView::Helpers::FormBuilder
  INPUT_CLASS = "win-input w-full"
  LABEL_CLASS = "block font-semibold mb-1 text-sm"

  %i[text_field email_field password_field number_field text_area datetime_local_field date_field].each do |method_name|
    define_method(method_name) do |attribute, options = {}|
      options[:class] ||= INPUT_CLASS
      super(attribute, options)
    end
  end

  def select(method, choices = nil, options = {}, html_options = {}, &block)
    html_options[:class] ||= INPUT_CLASS
    super(method, choices, options, html_options, &block)
  end

  def label(attribute, text = nil, options = {}, &block)
    options[:class] ||= LABEL_CLASS
    super(attribute, text, options, &block)
  end

  # Renders a label + input as a single unit, e.g. f.labeled_field :phone
  def labeled_field(attribute, label_text = nil, as: :text_field, **options)
    @template.content_tag(:div) do
      label(attribute, label_text, class: LABEL_CLASS) + public_send(as, attribute, options)
    end
  end
end
