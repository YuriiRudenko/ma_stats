class Doc
  require 'google/apis/sheets_v4'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'
  require 'fileutils'

  IT_WORDS = %w[войти вайти].freeze

  class << self
    def call(...)
      new(...).get
    end
  end

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file(ENV['CREDENTIALS_PATH'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: ENV['TOKEN_PATH'])
    authorizer = Google::Auth::UserAuthorizer.new(client_id, ENV['SCOPE'], token_store)
    user_id = 'default'
    authorizer.get_credentials(user_id)
  end

  def get
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = ENV['APPLICATION_NAME']
    service.authorization = authorize

    spreadsheet_id = ENV['SPREADSHEET_ID']
    students_charity = [
      [service.get_spreadsheet_values(spreadsheet_id, 'M2:M1000').values].flatten.map(&:to_f).sum,
      [service.get_spreadsheet_values(spreadsheet_id, 'S2:S1000').values].flatten.compact.map(&:to_f).sum,
      [service.get_spreadsheet_values(spreadsheet_id, 'AB2:AB1000').values].flatten.compact.map(&:to_f).sum,
      [service.get_spreadsheet_values(spreadsheet_id, 'AN2:AN1000').values].flatten.compact.map(&:to_f).sum,
      [service.get_spreadsheet_values(spreadsheet_id, 'AS2:AS1000').values].flatten.compact.map(&:to_f).sum,
      [service.get_spreadsheet_values(spreadsheet_id, 'AU2:AU1000').values].flatten.compact.map(&:to_f).sum,
    ].sum

    mentors_charity = [
      [service.get_spreadsheet_values(spreadsheet_id, 'AW2:AW1000').values].flatten.compact.map(&:to_f).sum,
    ].sum

    data = { charity: { students: students_charity, mentors: mentors_charity }, total_charity: students_charity + mentors_charity }
    data[:rating] = (service.get_spreadsheet_values(spreadsheet_id, 'H2:H1000').values || []).flatten.group_by { |i| i }.map { |k, v| [k, v.size] }.to_h
    data[:total] = data[:rating].values.sum
    value = (service.get_spreadsheet_values(spreadsheet_id, 'A2:Z1000').values || []).flatten.count { |v| IT_WORDS.any? { |w| w.in? v } }
    data[:voyti_v_it_rating] = data[:total].to_f.positive? ? value.to_f / data[:total] * 100 : 0
    data
  end
end