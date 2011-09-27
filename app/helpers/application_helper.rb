module ApplicationHelper

  def nice_duration(seconds)
    h = (seconds/3600).floor
    m = ((seconds - (h * 3600))/60).floor
    s = (seconds - (h * 3600 + m * 60)).round

    # return formatted time without hours if = 0
    hours = h == 0 ? "" : "#{'%02d' % h}:"
    return "#{hours}#{'%02d:%02d' % [ m, s ]}"
  end
end
