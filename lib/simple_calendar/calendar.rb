require 'rails'

module SimpleCalendar
  class Calendar
    PARAM_KEY_BLACKLIST = :authenticity_token, :commit, :utf8, :_method, :script_name

    attr_accessor :view_context, :options

    def initialize(view_context, opts={})
      @view_context = view_context
      @options = opts

      @params = @view_context.respond_to?(:params) ? @view_context.params : Hash.new
      @params = @params.to_unsafe_h if @params.respond_to?(:to_unsafe_h)
      @params = @params.with_indifferent_access.except(*PARAM_KEY_BLACKLIST)
    end

    def render(&block)
      view_context.render(
        partial: partial_name,
        locals: {
          block: block,
          calendar: self,
          date_range: date_range,
          start_date: start_date,
          sorted_events: sorted_events
        }
      )
    end

    def td_classes_for(day)
      today = Time.zone.now.to_date

      td_class = ["day"]
      td_class << "wday-#{day.wday.to_s}"
      td_class << "today"         if today == day
      td_class << "past"          if today > day
      td_class << "future"        if today < day
      td_class << 'start-date'    if day.to_date == start_date.to_date
      td_class << "prev-month"    if start_date.month != day.month && day < start_date
      td_class << "next-month"    if start_date.month != day.month && day > start_date
      td_class << "current-month" if start_date.month == day.month
      td_class << "has-events"    if sorted_events.fetch(day, []).any?

      td_class
    end

    def url_for_next_view
      view_context.url_for(@params.merge(start_date: date_range.last + 1.day))
    end

    def url_for_previous_view
      view_context.url_for(@params.merge(start_date: date_range.first - 1.day))
    end

    private

      def partial_name
        self.class.name.underscore
      end

      def start_attribute
        options.fetch(:start_attribute, :start_time).to_sym
      end

      def end_attribute
        options.fetch(:end_attribute, :end_time).to_sym
      end

      def sorted_events
        events = options.fetch(:events, []).sort_by(&start_attribute)

        events_with_start_attribute = events.reject { |e| e.send(start_attribute).nil? }

        scheduled = {}

        for event in events_with_start_attribute
          if event.has_attribute?(end_attribute)
            puts "Hat EndAttribute!"
            for date in event.send(start_attribute).to_date..event.send(end_attribute).to_date do
              temp  = { date => event}
              scheduled.merge!(temp) { |k, o, n| 
              if o.nil?
                puts "o ist nil!"
                o = Array.new
                o << n
              else
                o << n
              end
            }
            end
          else
            puts "Hat kein EndAttribute"
            temp = { event.send(start_attribute).to_date => event}
            scheduled.merge!(temp) { |k, o, n| 
              if o.nil?
                o = Array.new
                o << n
              else
                o << n
              end
            }
          end
        end

        #scheduled = events.reject { |e| e.send(start_attribute).nil? }
        #scheduled.group_by { |e| e.send(start_attribute).to_date }
        puts scheduled
        puts scheduled.inspect
        scheduled
      end

      def start_date
        if options.has_key?(:start_date)
          options.fetch(:start_date).to_date
        else
          view_context.params.fetch(:start_date, Date.today).to_date
        end
      end

      def date_range
        (start_date..(start_date + additional_days.days)).to_a
      end

      def additional_days
        options.fetch(:number_of_days, 4) - 1
      end
  end
end
