# =============================================================================
# ** Custom Skill Order
# * By YuriSH
# -----------------------------------------------------------------------------
# Allows you to change skill's order.
# Put "<skill order: number>" in skill's notes to change its order.
# "number" could be any number from 1 to 999.
# If note is not present, it will use skill's ID just like usual.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_CustomSkillOrder"] = true

module YuriSH
  module Const
    EXPR_SKILL_ORDER = /<skill order: (\d{1,3})>/i
  end
end

#==============================================================================
# ** Window_SkillList
#==============================================================================

class Window_SkillList < Window_Selectable
  #--------------------------------------------------------------------------
  # * Get New ID
  #--------------------------------------------------------------------------
  def get_new_id(skill_id)
    match_data = $data_skills[skill_id].note.match(YuriSH::Const::EXPR_SKILL_ORDER)
    if match_data.nil?
      return skill_id
    else
      return match_data[1].to_i
    end
  end
  #--------------------------------------------------------------------------
  # Alias: make_item_list
  #--------------------------------------------------------------------------
  alias make_item_list_yurish  make_item_list
  def make_item_list
    make_item_list_yurish
    @data.sort_by! { |item| get_new_id(item.id) }
  end
end