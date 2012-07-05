class Snapshot < ActiveRecord::Base
  self.abstract_class = true

  class_attribute :required_attrs, :identifying_attrs, :optional_attrs, :transient_ivars, :snapshot_attr

  def self.takes_snapshots_of(cls, options={})
    @domain_class = cls
    self.snapshot_attr = options[:column] || cls.to_s.underscore
    serialize self.snapshot_attr, @domain_class
  end

  def self.can_be_identified_by(*attr_names)
    self.identifying_attrs = attr_names
    (class << self; self; end).send :define_method, :find_from_args do |options|
      identifying_options = Hash[options.select { |(k,v)| self.identifying_attrs.include?(k) }]
      self.first(:conditions => identifying_options)
    end
  end

  def self.required_attributes(*attr_names)
    self.required_attrs = attr_names
  end

  def self.optional_attributes(*attr_names)
    self.optional_attrs = attr_names
  end

  def self.transient_instance_variables(*attr_names)
    self.transient_ivars = attr_names
  end

  def self.before_snapshot(action)
    @before_snapshot = action
  end

  def self.find_or_create(options={})
    find_and_populate_from_db(options) || domain_instance_from_args(options, :save => true)
  end

  def self.find_or_build(options={})
    find_and_populate_from_db(options) || domain_instance_from_args(options, :save => false)
  end

  def self.find_and_populate_from_db(options)
    find_from_args(options).try(self.snapshot_attr)
  end

  def self.domain_instance_from_args(options, config)
    (options[:domain_class] || @domain_class).new(options).tap do |instance|
      instance.send(@before_snapshot)
      save_a_snapshot(instance) if config[:save]
    end
  end

  def self.save_a_snapshot(obj)
    attrs_to_save = {self.snapshot_attr => obj}
    self.identifying_attrs.each do |attr_name|
      attrs_to_save[attr_name] = obj.send(attr_name)
    end
    self.new(attrs_to_save).save!
  end

  ## Instance-level behavior

  before_save :remove_transient_instance_variables

  validate :ensure_required_attrs_are_present
  validate :ensure_optional_attrs_can_respond

  private
  def remove_transient_instance_variables
    poro = snapshot_instance
    self.class.transient_ivars.each do |attr_name|
      poro.send :remove_instance_variable, "@#{attr_name}"
    end
  end

  def ensure_required_attrs_are_present
    (identifying_attrs + self.class.required_attrs).each do |attr_name|
      if snapshot_instance.send(attr_name) == nil
        errors[self.class.snapshot_attr] << "#{attr_name} can't be nil"
      end
    end
  end

  def ensure_optional_attrs_can_respond
    (self.class.optional_attrs).each do |attr_name|
      unless snapshot_instance.respond_to?(attr_name)
        errors[self.class.snapshot_attr] << "must respond to #{attr_name}"
      end
    end
  end

  def snapshot_instance
    self.send(self.class.snapshot_attr)
  end
end



