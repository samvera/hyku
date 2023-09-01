class DepartmentAttributeRenderer < Hyrax::Renderers::AttributeRenderer
  def attribute_value_to_html(value)
    %(<span itemprop="department">#{::DepartmentsService.label(value)}</span>)
  end
end