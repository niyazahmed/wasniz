class FkController < ApplicationController
  extend CommonConstants
  extend FlipkartAdapter
  def index
    render text: "FlipKart"
  end
  
  def search
    render text: FlipkartAdapter::search(params[:product])
  end
 
end