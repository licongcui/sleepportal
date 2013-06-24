class ReportConcept < ActiveRecord::Base
  STATISTIC = ["all", "avg", "min", "max"].collect{|i| [i,i]}

  # Model Relationships
  belongs_to :report
  belongs_to :concept

  # Only for external keys
  belongs_to :source

  def source
    if self.source_id and selected_source = Source.find_by_id(self.source_id)
      selected_source
    else
      self.concept.sources.first
    end
  end

  def copyable_attributes
    self.attributes.reject{|key, val| ['id', 'report_id', 'created_at', 'updated_at'].include?(key.to_s)}
  end

end
