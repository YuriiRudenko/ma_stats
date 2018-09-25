class Doc
  require 'google/apis/sheets_v4'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'
  require 'fileutils'

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Google Sheets API Ruby Quickstart'.freeze
  CREDENTIALS_PATH = "#{Rails.root}/credentials.json".freeze
  TOKEN_PATH = "#{Rails.root}/token.yaml".freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
  IT_WORDS = %w[войти вайти].freeze

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    authorizer.get_credentials(user_id)
  end

  def get
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize

    spreadsheet_id = '12iw3GaZ0KwX6sJDcTaBDp9dTP7L9-VTpZ6jhEU0j3Xw'
    response = service.get_spreadsheet_values(spreadsheet_id, 'T1:T1')
    data = { total_charity: response.values.flatten.first }
    data[:rating] = service.get_spreadsheet_values(spreadsheet_id, 'H3:H1000').values.flatten.group_by { |i| i }.map { |k, v| [k, v.size] }.to_h
    data[:total] = data[:rating].values.sum
    value = service.get_spreadsheet_values(spreadsheet_id, 'A2:Z1000').values.flatten.count { |v| IT_WORDS.any? { |w| w.in? v } }
    data[:voyti_v_it_rating] = value.to_f / data[:total] * 100
    data
  end
end