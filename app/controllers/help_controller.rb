class HelpController < ApplicationController

  # We cannot do page caching easily with cobranding, since different
  # requests generate different versions of the cached page
  # caches_page :index, :how_it_works, :payment, :legal, :technical, :other

  # Main help page
  def index
  end

  def how_it_works
  end

  def univ_faq
    @univ_stubs = UnivStub.find(:all)
  end

  def payment
  end

  def legal
  end

  def technical
  end

  def video_bundles
  end

  def other
  end

end
