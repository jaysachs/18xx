# frozen_string_literal: true

if RUBY_ENGINE == 'opal'
  require_tree 'ability'
else
  require 'require_all'
  require_rel 'ability'
end

module Engine
  module Abilities
    def init_abilities(abilities)
      @abilities = {}

      (abilities || []).each do |ability|
        klass = Ability::Base.type(ability[:type])
        ability = Object.const_get("Engine::Ability::#{klass}").new(**ability)
        raise 'Duplicate abilities detected' if @abilities[ability.type]

        ability.owner = self
        @abilities[ability.type] = ability
      end
    end

    def abilities(type)
      return nil unless (ability = @abilities[type])

      correct_owner_type =
        case ability.owner_type
        when :player
          !owner || owner.player?
        when :corporation
          owner&.corporation?
        when nil
          true
        end

      return nil unless correct_owner_type

      yield ability if block_given?
      ability
    end

    def add_ability(ability)
      ability.owner = self
      @abilities[ability.type] = ability
    end

    def remove_ability(type)
      @abilities.delete(type)
    end

    def remove_ability_when(time)
      @abilities.dup.each do |type, ability|
        remove_ability(type) if ability.when == time
      end
    end

    def all_abilities
      @abilities.map { |type, _| abilities(type) }.compact
    end
  end
end
