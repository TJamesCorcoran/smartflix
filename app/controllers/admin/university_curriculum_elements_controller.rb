class Admin::UniversityCurriculumElementsController < Admin::Base
  def get_class() UniversityCurriculumElement end

  def index
    @items = UniversityCurriculumElement.find(:all)
  end

  def show
    @item = UniversityCurriculumElement.find(params[:id])
  end

end
