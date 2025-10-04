ActiveAdmin.register Description do
  # Permit all parameters by default
  permit_params do
    Description.column_names.map(&:to_sym)
  end

  # Index page customization
  index do
    selectable_column
    id_column
    Description.column_names.each do |column|
      column column.to_sym unless column == "id"
    end
    actions
  end

  # Show page customization
  show do
    attributes_table do
      Description.column_names.each do |column|
        row column.to_sym
      end
    end
  end

  # Form customization
  form do |f|
    f.inputs do
      Description.column_names.each do |column|
        f.input column.to_sym unless column == "id" || column.end_with?("_at") || column == "created_at" || column == "updated_at"
      end
    end
    f.actions
  end
end
