class String
  def digest (max, tail_adjust = '$')
    euc = NKF::nkf('-e', self)
    if euc .size <= max
      return euc
    end
    euc = euc[0..max-1]
    if euc[max-1] == 164
      euc[max-1] = tail_adjust
    end
    euc
  end
end

