class CreateHolidays < ActiveRecord::Migration
  def change
    add_column :holidays, :year, :integer
  end
end
