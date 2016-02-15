class Admin::ProductsController < Admin::Base
  def get_class() Product end

  def setup
    @authors =    Author.find(:all, :order => "name" ).map {|x| [ x.name, x.author_id ]  }

    @categories =["none", 0] + Category.find(:all, :order => "description").reject { |c| c.childCats.any? }.map {|x| [ x.full_name, x.category_id ]  }.sort { |a,b| a[0] <=> b[0] }

    @vendors =   Vendor.find(:all, :order => "name" ).map {|x| [ x.name, x.vendor_id ]  }
    @product_sets = ProductSet.find(:all, :order => "name" ).map {|x| [ x.name, x.product_set_id ]  }
    @ordinals =  [ ["none", 0], [1,1], [2,2], [3,3], [4,4], [5,5], [6,6], [7,7], [8,8], [9,9], [10,10], [11,11], [12,12]]
    @prices =  [ ["auto - base on purchase price", 0], [9.99, 9.99], [14.99, 14.99], [19.99, 19.99]]
  end

  def index
    if (params[:handout].nil?)
      params[:search_str] = "%" + params[:search_str].to_s + "%"
      @products = Product.where(["name like ?", params[:search_str] ])
    else
      @products = Product.where(["! ISNULL(handout) && handout != ''"])
    end
    @products = @products.order("name").paginate( :page => ( params["page"] || 1).to_i)

  end

  def add_cat
    cat = Category[params[:cat][:cat].to_i]
    prod = Product[params[:prod].to_i]
    
    unless cat
      flash[:error] = "invalid cat"
      redirect_to :back
    end
    
    unless prod
      flash[:error] = "invalid prod"
      redirect_to :back
    end
    
    begin
      prod.categories << cat
      prod.save!
    rescue Exception  => e 
      flash[:error] = e.message
      return redirect_to :back
    end
    
    flash[:notice] = "added #{cat.name}"
    redirect_to :back
    
  end

  def remove_cat
    cat = Category[params[:cat].to_i]
    prod = Product[params[:prod].to_i]

    unless cat
      flash[:error] = "invalid cat"
      redirect_to :back
    end

    unless prod
      flash[:error] = "invalid prod"
      redirect_to :back
    end

    begin
      prod.categories = (prod.categories - [cat])
      prod.save!
    rescue Exception  => e 
      flash[:error] = e.message
      return redirect_to :back
    end

    flash[:notice] = "remove from #{cat.name}"
    redirect_to :back
  end



  def need_prices
    if (!params[:overdue].nil?)
      @products = Product.no_prices_on_overdue
    else
      @products = Product.find(:all, :conditions => "ISNULL(purchase_price)", :order => "name" )
    end
  end

  def write_prices
    modified = []
    params[:product].each do |id, price|
      if price.to_f > 0
        product = Product.find(id)
        rental_price = Product.purchase_price_to_rental_price(price.to_i)
        product.update_attributes(:purchase_price => price, :price=> rental_price )       
        modified << product.name
      end
    end
    flash[:notice] = "updated: #{modified.size} products: " + modified.join(",")
    redirect_to :action => "need_prices"
  end

  def dnu
    @products = Video.find(:all, :conditions => "name like '%DNU%'", :order => "name" )
  end

  def merge
    @product = Product.find(params[:id])
    @products   = Video.find(:all, :order => "name" ).map {|x| [ "#{x.name} (#{x.id}) ", x.id ]  } 
    if (request.post?)
      @target = Product[params["product_target"]["target"].to_i]
      @product.duplicate_of_other_product(@target)
      flash[:notice] = "merged #{@product.id} #{@product.name} into  #{@target.id} #{@target.name} "
      redirect_to :action => :show, :id => @target
    end
  end
  
  def show
    # XYZFIX P3 duplicate code from controllers/purchasings_controller.rb
    @purchasers = Purchaser.find(:all, :conditions=>"activeP = 1").map {|x| [ x.name_first + " " + x.name_last, x.id ]  }
    @quant_choices =  [ [0, 0], [1,1], [2,2], [3,3], [4,4], [5,5], [6,6], [7,7], [8,8], [9,9], [10,10], [11,11], [12,12]]

    @product = Product.find(params[:id])
    @unshipped_lis = @product.unshipped_lis

    respond_to do |format|
      format.html
    end
  end

  def new
    @product = Product.new
    @product_set_membership = ProductSetMembership.new
    @product_set_membership.ordinal = 0
    setup

  end

  def edit
    @product = Product.find(params[:id])
    @product_set_membership = @product.product_set_membership
    setup
  end

  def create
    params[:product][:price] = Product.purchase_price_to_rental_price(params[:product][:purchase_price].to_i) if 0 == params[:product][:price].to_i
    params[:product][:date_added] = Date.today    

    @product = Video.new(params[:product])

    # assign a handout code, if needed
    if (@product.handout.to_i == 1)
      maxhandproduct = Product.find(:first,
                                :order=> "(substring(handout,2,10) + 0) desc",
                                :conditions => "! ISNULL(handout)")
      @product.handout = maxhandproduct.handout.succ
    else
      @product.handout = ""
    end

    begin
      if (! params[:product_set_membership].nil? &&
          (0 != params[:product_set_membership]["ordinal"].to_i))
        @product.product_set_membership = ProductSetMembership.new(params[:product_set_membership])
      end
      # test that 1 or more categories were set
      # if not, abort early
      catcount = 0
      (1..5).each do | x |
        if ("none" != params["category#{x}"][:category] )
          @product.categories.push(Category.find(params["category#{x}"][:category]))
          catcount = catcount + 1
        end
      end
      if (catcount == 0)
        raise "must pick 1+ category"
      end

      # why do we save them in this order?  
      #
      # a simple save of @product would work, and it would trigger a
      # save of @product.product_set_membership, but on failure of
      # @product.product_set_membership, no alarm gets raised...so we
      # do it this way instead 
      #
      # see _Agile Web Development with Rails_, p. 357
      #
      if (@product.product_set_membership)
        @product.product_set_membership.save!
      end
      @product.save!

      flash[:notice] = "product '#{@product.name}' created"
      redirect_to :action => :show, :id => @product

     rescue
       if (! @product.product_set_membership.nil?)
         ProductSetMembership.delete(@product.product_set_membership.id)
       end
       if (! @product.id.nil?)
         Product.delete(@product.id)
       end
       setup
       flash[:error] = "product not created!!! - #{$!}"
       render :action => "new"
       return
    end


  end

  def update
    @product = Product.find(params[:id])

    params[:product][:price] = Product.purchase_price_to_rental_price(params[:product][:purchase_price].to_i) if 0 == params[:product][:price].to_i

    
    # build a product_set_membership from user data
    #
    smOld = @product.product_set_membership
    smNew = ProductSetMembership.new(params[:product_set_membership])
    smNew.product_id = @product.product_id
    if (! smOld.nil?)
      smOld.update_attributes(smNew.attributes)
    else
      smOld = smNew
    end
    # post-condition: smOld has same primary key as before (if there was one), and new data

    if(smOld.ordinal > 0)
      smOld.save()
    else
      smOld.destroy()
    end

    # Suz request: if she edits the price or vendor on a product in a set, change
    # those details for all products in the set
    others = Array.new
    if (@product.product_set)
      @product.product_set.products.reject{|x| x.id == @product.id}.each do |other_product|
        # can't just use other_product - it's readonly.  have to do this workaround
        tt = Product.find(other_product.id)
        others.push(tt)
      end
    end
    errata = ""
    if (others.size > 0) then errata = "...also modified " + others.collect{|tt| tt.id}.join(", ") end

    if @product.update_attributes(params[:product])
      others.each do |oo|
        oo.update_attributes(:vendor_id => @product.vendor_id, :purchase_price => @product.purchase_price)
      end
      flash[:notice] = "Product was successfully updated. #{errata}"
      redirect_to :action => :show, :id => @product
    else
      setup
      render :action => "edit"
    end


  end

  def destroy
    @product = Product.find(params[:id])
    @product.destroy

    respond_to do |format|
      format.html { redirect_to products_url }
      format.xml  { head :ok }
    end
  end
end
