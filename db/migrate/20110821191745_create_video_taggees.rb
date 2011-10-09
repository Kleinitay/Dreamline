class CreateVideoTaggees < ActiveRecord::Migration

  def self.up
    create_table :video_taggees do |t|
      t.column "contact_id",       :string, :null => false
      t.column "video_id",         :string, :null => false
      t.column "created_at",       :datetime        
    end
  end

  def self.down
    drop_table :video_taggees
  end
end
