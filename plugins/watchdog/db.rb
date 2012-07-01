# -*- coding: utf-8 -*-
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

require 'nkf'

module Watchdog
  REPOSITORY_NAME = :watchdog

  def self.connect(uri)
    DataMapper.setup(REPOSITORY_NAME, uri)
    Watchdog::Page.auto_upgrade!
  end

  ######################################################################
  ### Page

  class Page
    def self.default_repository_name; REPOSITORY_NAME; end
    def self.default_storage_name   ; "page"; end

    include DataMapper::Resource

    property :id        , Serial
    property :name      , String, :length=>255       # 件名
    property :url       , String, :length=>255       # 詳細
    property :digest    , String, :length=>255       # DIGEST値
    property :changed   , Boolean , :default=>false  # 更新済
    property :start_at  , DateTime                   # 

    ######################################################################
    ### Class methods

    class << self
      def changed
        all(:changed=>true, :order=>[:id])
      end

      def current
        all(:changed=>false, :order=>[:id]).select{|p|
          ! p.start_at or p.start_at.to_time <= Time.now
        }
      end
    end

    ######################################################################
    ### Operations

    include Ircbot::Utils::HtmlParser

    def update!
      html = Open3.popen3("curl", url) {|i,o,e| o.read{} }
      utf8 = NKF.nkf("-w", html)
      hex  = Digest::SHA1.hexdigest(utf8)
      self[:changed]    = !! ( self[:changed] || (digest && (digest != hex)) )
      self[:name]       = get_title(utf8)
      self[:digest]     = hex
      save
      return self[:changed]
    end

    ######################################################################
    ### Instance methods

    def done!
      self[:changed] = false
      save
    end

    def cooltime!(sec)
      self[:start_at] = Time.now + sec
      done!
    end

    def to_s
      "#{name} #{url}"
    end
  end
end
