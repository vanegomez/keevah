require "logger"
require "pry"
require "capybara"
require 'capybara/poltergeist'
require "faker"
require "active_support"
require "active_support/core_ext"

module LoadScript
  class Session
    include Capybara::DSL
    attr_reader :host
    def initialize(host = nil)
      Capybara.default_driver = :poltergeist
      @host = host || "http://localhost:3000"
    end

    def logger
      @logger ||= Logger.new("./log/requests.log")
    end

    def session
      @session ||= Capybara::Session.new(:poltergeist)
    end

    def run
      while true
        run_action(actions.sample)
      end
    end

    def run_action(name)
      benchmarked(name) do
        send(name)
      end
    rescue Capybara::Poltergeist::TimeoutError
      logger.error("Timed out executing Action: #{name}. Will continue.")
    end

    def benchmarked(name)
      logger.info "Running action #{name}"
      start = Time.now
      val = yield
      logger.info "Completed #{name} in #{Time.now - start} seconds"
      val
    end

    def actions
      [:sign_up_as_lender, :sign_up_as_borrower, :browse_loan_requests, :browse_loan_requests_pages, :browse_categories, :browse_categories_pages, :view_a_loan_request, :lender_makes_loan, :borrower_creates_loan_request ]
    end

    def categories
      ["Agriculture", "Education", "Community"]
    end

    def new_user_name
      "#{Faker::Name.name} #{Time.now.to_i}"
    end

    def new_user_email(name)
      "TuringPivotBots+#{name.split.join}@gmail.com"
    end

    def log_in(email="demo+horace@jumpstartlab.com", pw="password")
      log_out
      session.visit host
      session.click_link("Log In")
      session.fill_in("email_address", with: email)
      session.fill_in("password", with: pw)
      session.click_link_or_button("Login")
    end

    def log_out
      session.visit host
      if session.has_content?("Log out")
        session.find("#logout").click
      end
    end

    def browse_loan_requests
      session.visit "#{host}/browse"
      session.all(".lr-about").sample.click
    end

    def browse_loan_requests_pages
      log_in
      session.visit "#{host}/browse"
      session.all(".lr-about").sample.click
      session.all(".pagination a").sample.click
      puts "Browsing loan request pages"
    end

    def browse_categories
      log_in
      session.visit "#{host}/browse"
      session.all(".category").sample.click
      puts "Browsing by category"
    end

    def browse_categories_pages
      log_in
      session.visit "#{host}/browse"
      session.all(".category").sample.click
      session.all(".pagination a").sample.click
      puts "Browsing by category pages"
    end

    def view_a_loan_request
      log_in
      session.visit "#{host}/browse"
      session.all("a.lr-about").sample.click
      puts "Viewing an individual loan request"
    end

    def sign_up_as_lender(name = new_user_name)
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-lender").click
      session.within("#lenderSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
      puts "Sign-up as a Lender"
    end

    def sign_up_as_borrower(name = new_user_name)
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-borrower").click
      session.within("#borrowerSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
      puts "Sign-up as a new Borrower"
    end

    def lender_makes_loan
      sign_up_as_lender
      browse_loan_requests
      session.click_link_or_button("Contribute $25")
      session.click_link_or_button("Basket")
      session.click_link_or_button("Transfer Funds")
      log_out
      puts "Lender makes a loan"
    end

    def borrower_creates_loan_request
      log_out
      sign_up_as_borrower
      session.click_link_or_button("Create Loan Request")
      session.within("#loanRequestModal") do
        session.fill_in("loan_request_title", with: Faker::Commerce.product_name)
        session.fill_in("loan_request_description", with: Faker::Company.catch_phrase)
        session.fill_in("loan_request_requested_by_date", with: Faker::Time.between(7.days.ago, 3.days.ago))
        session.fill_in("loan_request_repayment_begin_date", with: Faker::Time.between(3.days.ago, Time.now))
        session.select("Agriculture", from: "loan_request_category")
        session.fill_in("loan_request_amount", with: "200")
        session.click_link_or_button("Submit")
      end
      puts "Borrower creates a loan request"
    end
  end
end
