# encoding: utf-8

module SmartSMS
  # Module that contains methods to generate fake message
  #
  module FakeSMS
    module_function

    # This will generate fake sms with all necessary attributes
    #
    # Options:
    #
    #   * mobile: mobile number
    #   * code:   verification code
    #
    def build_fake_sms(mobile, code)
      {
        'sid'               => SecureRandom.uuid,
        'mobile'            => mobile,
        'send_time'         => Time.zone.now,
        'text'              => "您的验证码是#{code}。如非本人操作，请忽略本短信",
        'send_status'       => 'SUCCESS',
        'report_status'     => 'FAKE',
        'fee'               => 1,
        'user_receive_time' => nil,
        'error_msg'         => nil
      }
    end
  end
end
