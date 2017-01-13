# frozen_string_literal: true

# Community Tool is a user submitted tool
class CommunityTool < ApplicationRecord
  # Constants
  STATUS = %w(started submitted accepted rejected)

  # Concerns
  include Deletable, Sluggable, Searchable

  # Callbacks
  after_touch :recalculate_rating!

  # Model Validation
  validates :user_id, :url, :status, presence: true
  validates :name, :description, presence: true, if: :published?
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }, if: :published?
  validates :url, format: URI.regexp(%w(http https ftp))
  validates :slug, uniqueness: { case_sensitive: false }, allow_nil: true
  validates :slug, format: { with: /\A[a-z][a-z0-9\-]*\Z/ }, allow_nil: true

  # Model Relationships
  belongs_to :user
  has_many :community_tool_reviews, -> { order(rating: :desc, id: :desc) }

  # Community Tool Methods

    def self.searchable_attributes
      %w(name description series)
    end

  def draft?
    !published?
  end

  def destroy
    update name: nil, slug: nil
    super
  end

  def editable_by?(current_user)
    current_user && (current_user.system_admin? || current_user == user)
  end

  def safe_url?
    %w(http https ftp).include?(URI.parse(url).scheme)
  rescue
    false
  end

  def recalculate_rating!
    ratings = community_tool_reviews.where.not(rating: nil).pluck(:rating)
    update rating: ratings.present? ? ratings.inject(&:+).to_f / ratings.count : nil
  end

  def readme_content
    if readme_url.present?
      uri = URI.parse(readme_url)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      req = Net::HTTP::Get.new(uri.path)
      response = http.start do |http|
                   http.request(req)
                 end
      response.body
    end
  rescue
    nil
  end

  def readme_url
    if github_readme?
      url.gsub(%r{^https://github.com/}, 'https://raw.githubusercontent.com/') + '/master/README.md'
    elsif github_gist?
      url.gsub(%r{^https://gist.github.com/}, 'https://gist.githubusercontent.com/') + '/raw'
    end
  end

  def github_gist?
    %r{^https://gist.github.com/} =~ url
  end

  def github_readme?
    %r{^https://github.com/} =~ url
  end

  def markdown?
    if github_gist?
      uri = URI.parse(url + '.json')
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      req = Net::HTTP::Get.new(uri.path)
      response = http.start do |http|
                   http.request(req)
                 end
      filename = JSON.parse(response.body)['files'].first
      /\.md$/ =~ filename || /\.markdown$/ =~ filename
    else
      github_readme?
    end
  rescue
    false
  end

  def started?
    status == 'started'
  end
end
