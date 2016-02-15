module UnivstoreHelper

  def image_file_for_univ(univ)
    "/images/univstore/uni_banner_#{univ.id}_#{univ.name.split[0].downcase}.jpg"
  end

end
