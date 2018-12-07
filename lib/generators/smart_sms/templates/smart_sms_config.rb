# encoding: utf-8

SmartSMS.configure do |config|
  config.api_key = nil # 授权 API KEY
  config.api_version = :v2 # API 的版本, 当前仅有v2
  config.template_id = '2' # 指定发送信息时使用的模板
  # config.company = '英 选' # 默认公司名称
  # config.template_value = [:code, :company] # 用于指定信息文本中的可替换内容, 数组形势: [:code, :company]
  # config.page_num = 1 # 获取信息时, 指定默认的页数
  # config.page_size = 20 # 获取信息时, 一页包含信息数量
  # config.expires_in = 5.minutes # 短信验证过期时间
  # config.default_interval = 1.day # 查询短信时的默认时间段: end_time - start_time
  # config.store_sms_in_local = false # 是否存储SMS信息在本地: true or false
  # config.verification_code_algorithm = :simple # 提供三种形式的验证码: `:simple, :middle, :complex`
end