class CreateDcsDates < ActiveRecord::Migration
  def change
    create_table :dcs_dates do |t|
      t.date :date
      t.column :date_type, "ENUM('accepted', 'available', 'copyrighted', 'collected', 'created',
                                  'issued', 'submitted', 'updated', 'valid')" default: nil
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end

