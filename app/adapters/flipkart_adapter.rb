# encoding: UTF-8
module FlipkartAdapter
  extend CommonConstants
  
  @@agent = Mechanize.new { |agent| agent.user_agent_alias = "Mac Safari" }

  def self.search(searchText)
    uri = URI CommonConstants::FLIPKART_BASE_URL
    page = @@agent.get(uri)
    searchForm = page.form_with(:id=>'fk-header-search-form')
    if !searchForm.nil?
      searchForm['q'] = searchText
      searchResults = searchForm.submit
      read_productList(searchResults)
    end
  end
  
  private
  def self.read_productList(searchResults)
    doc = Nokogiri::HTML(searchResults.body)
    productList = doc.xpath("//a[@data-tracking-id='prd_title']")
    
    #NOTE THIS WILL GET ONLY THE FIRST 20 SEARCH RESULT. I am not extending for all phones yet.
    # Its easy to do all. In order to have minimum info for us to design the page
 
    response = {}
    productList.each do |product|
      if !product.nil?
        p product['title']
        response[product['title']]= read_productReviewPage(product)
      end
    end
   p response
  end
  
  private
  def self.read_productReviewPage(product)
    specificProductPage = @@agent.get(CommonConstants::FLIPKART_BASE_URL+product['href'])
    html = specificProductPage.link_with(:text => 'Show ALL').click
    productReviews = []
    loop do
      productReviews =  productReviews + read_review(html)
      if nextPage = html.link_with(:text  => 'Next Page ›')
        html = nextPage.click
      else
        #This is the last page of the total reviews so break out of the loop
        break
      end
    end
    productReviews
  end
  
  private
  def self.read_review(html)
    html.encoding = 'utf-8'
    html_doc = Nokogiri::HTML(html.body)
    review_list= html_doc.search("[@review-id]")
    page_reviews = []
    review_list.each do |review|
      page_reviews << extractReviewInfo(review)
    end
   p page_reviews
   page_reviews
  end
  
  private
  
  def self.extractReviewInfo(review)
    reviews = {}
    reviewName = review.search("[@profile_name]")
    reviews[:reviewer_name] = reviewName.text.strip!
    otherReviews = nil
    if (!reviewName.nil? && !reviewName.empty?) 
      otherReviews = reviewName.attribute('href').value     
    end
    reviews[:other_reviews] = otherReviews
    reviews[:review_date] = review.css('div.date').text.strip!
    reviews[:star] = review.css('div.fk-stars').attribute('title').value
    certified_buyer_img = review.css('img')
    certified_buyer = false
    if !certified_buyer_img.nil? && !certified_buyer_img.empty?
      certified_buyer = certified_buyer_img.attribute('alt').value == 'certified buyer'
    end
    reviews[:certified_buyer] = certified_buyer
    reviews[:review_title] = review.css('div.line.fk-font-normal strong').text.strip!
    reviews[:review_text] = review.css('span.review-text').text.strip!
    reviews
  end
  
  
  #  sample response
  #  response ={"MOTO G" : [
  #   {:reviewer_name=>"Himanshu Sharma", 
  #     :other_reviews=>"http://www.flipkart.com/user-profiles/Crazymady?tab=product-reviews",
  #     :review_date=>"21 Jul 2015",
  #     :star=>"2 stars",
  #      :certified_buyer=>true, 
  #      :review_title=>"Some Title"
  #      :review_test => 'review information'
  #    },
  #    {:reviewer_name=>"Himanshu Sharma", 
  #      :other_reviews=>"http://www.flipkart.com/user-profiles/Crazymady?tab=product-reviews",
  #      :review_date=>"21 Jul 2015",
  #      :star=>"2 stars",
  #      :certified_buyer=>true, 
  #      :review_title=>"Some Title"
  #      :review_test => 'review information'
  #   }
  #    ] ,
  #    "Iphone" = [...]
  #}
 
end