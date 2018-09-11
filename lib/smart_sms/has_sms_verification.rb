# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'model/message'))

module SmartSMS
  # Module that will be hooked into ActiveRecord to provide magic methods
  #
  module HasSmsVerification
    def self.included(base)
      base.send :extend, ClassMethods
    end

    # Class methods that will be extended
    module ClassMethods

      # 在您的Model里面声明这个方法, 以添加SMS短信验证功能
      #
      # * moible_column:       mobile 绑定的字段, 用于发送短信, 默认 :mobile
      # * verification_column: 验证绑定的字段, 用于判断是否已验证, 默认 :mobile_verified_at
      #
      # Options:
      #   * :class_name   自定义的Message类名称. 默认是 `::SmartSMS::Message`
      #   * :messages     自定义的Message关联名称.  默认是 `:messages`.
      #
      def has_sms_verification(moible_column = :mobile, verification_column = :mobile_verified_at, options = {})
        send :include, InstanceMethods

        # 用于判断是否已经验证的字段, Datetime 类型, 例如 :verified_at
        class_attribute :sms_verification_column
        self.sms_verification_column = verification_column

        class_attribute :sms_mobile_column
        self.sms_mobile_column = moible_column

        class_attribute :verify_regexp
        self.verify_regexp = /(【.+】|[^a-zA-Z0-9\.\-\+_])/ # 用于抽取校验码, 如若修改过模板, 可能需要修改这个这正则

        if SmartSMS.config.store_sms_in_local

          class_attribute :messages_association_name
          self.messages_association_name = options[:messages] || :sms_messages

          class_attribute :message_class_name
          self.message_class_name = options[:class_name] || '::SmartSMS::Message'

          if ::ActiveRecord::VERSION::MAJOR >= 4 # Rails 4 的 `has_many` 中定义order lambda的新语法
            has_many messages_association_name,
              -> { order('sent_at ASC') },
              class_name: message_class_name,
              as:         :smsable
          else
            has_many messages_association_name,
              class_name: message_class_name,
              as:         :smsable,
              order:      'sent_at ASC'
          end

        end
      end

      # Instance methods
      #
      module InstanceMethods
        # 非安全verify!方法, 验证成功后会存储成功的结果到数据表中
        #
        def verify_sms_code!(code)
          result = verify code
          if result
            send("#{self.class.sms_verification_column}=", Time.now)
            save(validate: false)
          end
        end

        # 安全verify方法, 用于校验短信验证码是否正确, 返回: true 或 false
        #
        def verify_sms_code(code)
          sms = latest_sms_message
          return false if sms.blank?
          if SmartSMS.config.store_sms_in_local
            sms.code == code.to_s
          else
            sms['text'].gsub(self.class.verify_regexp, '') == code.to_s
          end
        end

        # 判断是否已经验证成功
        #
        def mobile_verified?
          verified_at.present?
        end

        def mobile_verified_at
          self[self.class.sms_verification_column]
        end

        # 获取最新的一条有效短信记录
        #
        def latest_sms_message
          end_time = Time.now
          start_time = end_time - SmartSMS.config.expires_in
          if SmartSMS.config.store_sms_in_local
            send(self.class.messages_association_name)
              .where('sent_at >= ? and sent_at <= ?', start_time, end_time)
              .last
          else
            result = SmartSMS.find(
              start_time: start_time,
              end_time: end_time,
              mobile: send(self.class.sms_mobile_column),
              page_size: 1
            )
            result['sms'].first
          end
        end

        # 发送短信至手机
        #
        def send_sms(text = SmartSMS::VerificationCode.random)
          result = SmartSMS.deliver send(self.class.sms_mobile_column), text
          if result['code'] == 0
            sms = SmartSMS.find_by_sid(result['result']['sid'])['sms']
            save_or_return_message sms, text
          else
            errors.add :deliver, result
            false
          end
        end

        def send_fake_sms_code(text = SmartSMS::VerificationCode.random)
          mobile = send(self.class.sms_mobile_column)
          company = SmartSMS.config.company
          sms = SmartSMS::FakeSMS.build_fake_sms mobile, text, company
          save_or_return_message sms, text
        end

        private

        def save_or_return_message(sms, text)
          if SmartSMS.config.store_sms_in_local
            message = send(self.class.messages_association_name).build sms
            message.code = text
            message.save
          else
            sms
          end
        end
      end
    end
  end
end
