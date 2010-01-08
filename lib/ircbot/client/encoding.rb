# -*- coding: utf-8 -*-

module Ircbot
  class Client
    ######################################################################
    ### Character conversions

    def decode(text)
      NKF.nkf('-w', text.to_s)
    end

    def encode(text)
      NKF.nkf('-j', text.to_s)
    end
  end
end

