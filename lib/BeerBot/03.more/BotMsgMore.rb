# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require_relative '../00.utils/More'

module BeerBot

  # More-based filter that can be applies to botmsg's.
  #
  # #filter expects a botmsg and returns an array botmsg.

  class BotMsgMore < ::BeerBot::Utils::More
    def filter botmsg
      return nil unless botmsg
      arr = BeerBot::BotMsg.to_a(botmsg)
      return nil unless arr
      replies = []
      by_to = Hash.new{|h,k| h[k]=[]}

      arr.inject(by_to){|h,v| h[v[:to]].push(v); h}
      by_to.each_pair{|to,a|
        replies += super(a,to)
        if replies.size < a.size then
          replies += [msg:"Type: more",to:to]
        end
      }
      return replies
    end
  end

end
