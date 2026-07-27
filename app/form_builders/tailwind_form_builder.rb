class TailwindFormBuilder < ActionView::Helpers::FormBuilder
  INPUT_CLASS = "mt-1 block w-full rounded-md border-slate-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
  LABEL_CLASS = "block text-sm font-medium text-slate-700"

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

  # Renders a label + input as a single unit, e.g. f.labeled_field :phone
  def labeled_field(attribute, label_text = nil, as: :text_field, **options)
    @template.content_tag(:div) do
      label(attribute, label_text, class: LABEL_CLASS) + public_send(as, attribute, options)
    end
  end
end
