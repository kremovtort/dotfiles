{ inputs, lib, ... }:
let
  karabinix = inputs.karabinix.lib;
  # Import rules module directly since not all functions are exported in lib
  rules = import "${inputs.karabinix}/lib/rules.nix" { inherit lib; };
  inherit (karabinix) 
    keyCodes 
    mkProfile
    mkToEvent;
  inherit (rules)
    mkManipulator 
    mkFromEvent 
    mkRule 
    mkModifiers
    mkCondition;

  mkLayerManipulators = modifier: [
    # Navigation
    { from = "h"; to = "left_arrow"; }
    { from = "j"; to = "down_arrow"; }
    { from = "k"; to = "up_arrow"; }
    { from = "l"; to = "right_arrow"; }

    # Tab
    { from = "n"; to = "tab"; }
    { from = "p"; to = "tab"; toModifiers = [ "left_shift" ]; }
    
    # Media
    { from = "spacebar"; to = "play_or_pause"; }
    { from = "z"; to = "rewind"; }
    { from = "x"; to = "fastforward"; }

    # Volume
    { from = "comma"; to = "volume_down"; }
    { from = "period"; to = "volume_up"; }
    
    # F-Keys
    { from = "1"; to = "f1"; toModifiers = [ "fn" ]; }
    { from = "2"; to = "f2"; toModifiers = [ "fn" ]; }
    { from = "3"; to = "f3"; toModifiers = [ "fn" ]; }
    { from = "4"; to = "f4"; toModifiers = [ "fn" ]; }
    { from = "5"; to = "f5"; toModifiers = [ "fn" ]; }
    { from = "6"; to = "f6"; toModifiers = [ "fn" ]; }
    { from = "7"; to = "f7"; toModifiers = [ "fn" ]; }
    { from = "8"; to = "f8"; toModifiers = [ "fn" ]; }
    { from = "9"; to = "f9"; toModifiers = [ "fn" ]; }
    { from = "0"; to = "f10"; toModifiers = [ "fn" ]; }
    { from = "hyphen"; to = "f11"; toModifiers = [ "fn" ]; }
    { from = "equal_sign"; to = "f12"; toModifiers = [ "fn" ]; }
    
    # System
    { from = "open_bracket"; to = "escape"; }
    { from = "o"; to = "return_or_enter"; }
    { from = "delete_or_backspace"; to = "delete_forward"; }
    { from = "d"; to = "page_down"; }
    { from = "u"; to = "page_up"; }
    { from = "a"; to = "home"; }
    { from = "e"; to = "end"; }
    { from = "w"; to = "delete_or_backspace"; toModifiers = [ "left_option" ]; }
  ];

  # Преобразование конфига в манипуляторы karabinix
  createManipulators = modifier: map (m: mkManipulator {
    from = mkFromEvent {
      key_code = keyCodes.${m.from};
      modifiers = mkModifiers { mandatory = [ modifier ]; optional = [ "any" ]; };
    };
    to = [
      (mkToEvent ({
        key_code = keyCodes.${m.to};
      } // lib.optionalAttrs (m ? toModifiers) { modifiers = m.toModifiers; }))
    ];
  }) (mkLayerManipulators modifier);

  # Условие для конкретного устройства
  deviceCondition = deviceId: mkCondition {
    type = "device_if";
    identifiers = [ deviceId ];
  };

  # Правила для специфичных устройств
  mkDeviceSpecificRules = description: deviceId: [
    (mkManipulator {
      conditions = [ (deviceCondition deviceId) ];
      from = mkFromEvent { key_code = "f23"; };
      to = [ (mkToEvent { key_code = keyCodes.left_arrow; modifiers = [ "left_control" ]; }) ];
    })
    (mkManipulator {
      conditions = [ (deviceCondition deviceId) ];
      from = mkFromEvent { key_code = "f24"; };
      to = [ (mkToEvent { key_code = keyCodes.right_arrow; modifiers = [ "left_control" ]; }) ];
    })
  ];

  # Стандартные F1-F12 для Keychron
  keychronFnKeys = map (i: {
    from = { key_code = "f${toString i}"; };
    to = [{ key_code = "f${toString i}"; }];
  }) (lib.range 1 12);

in {
  services.karabinix = {
    enable = true;
    configuration = {
      global = {
        ask_for_confirmation_before_quitting = true;
        check_for_updates_on_startup = false;
        show_in_menu_bar = true;
      };
      profiles = [
        (mkProfile {
          name = "Default";
          selected = true;
          virtual_hid_keyboard = { keyboard_type_v2 = "ansi"; };
          complex_modifications = {
            parameters = {
              "basic.simultaneous_threshold_milliseconds" = 50;
              "basic.to_delayed_action_delay_milliseconds" = 500;
              "basic.to_if_alone_timeout_milliseconds" = 1000;
              "basic.to_if_held_down_threshold_milliseconds" = 500;
            };
            rules = [
              (mkRule "F19 to switch language" [
                (mkManipulator {
                  from = mkFromEvent { key_code = keyCodes.f19; };
                  to = [
                    (mkToEvent { key_code = keyCodes.spacebar; modifiers = [ "left_option" ]; })
                  ];
                })
              ])
              (mkRule "Layer (Ctrl/Fn)" (
                (createManipulators "left_control") ++ 
                (createManipulators "fn")
              ))
              (mkRule "BSK V3 PRO BT Specific" (mkDeviceSpecificRules "BSK V3 PRO BT" { product_id = 172; vendor_id = 1678; }))
              (mkRule "BSK V3 PRO G Specific" (mkDeviceSpecificRules "BSK V3 PRO G" { product_id = 171; vendor_id = 5426; }))
            ];
          };
          devices = [
            {
              identifiers = { is_keyboard = true; product_id = 171; vendor_id = 5426; };
              simple_modifications = [
                { 
                  from = { key_code = "f22"; }; 
                  to = [ 
                    { apple_vendor_keyboard_key_code = "mission_control"; } 
                  ]; 
                }
              ];
            }
            {
              identifiers = {
                is_keyboard = true;
                is_pointing_device = true;
                product_id = 172;
                vendor_id = 1678;
              };
              ignore = false;
            }
            {
              identifiers = {
                is_keyboard = true;
                is_pointing_device = true;
                product_id = 3616;
                vendor_id = 13364;
              };
              ignore = false;
            }
            {
              identifiers = {
                is_keyboard = true;
                product_id = 12870;
                vendor_id = 6645;
              };
              fn_function_keys = keychronFnKeys;
            }
            {
              identifiers = {
                is_keyboard = true;
                product_id = 53296;
                vendor_id = 13364;
              };
              fn_function_keys = keychronFnKeys;
            }
          ];
          simple_modifications = [
            { 
              from = { key_code = "f22"; };
              to = [
                { apple_vendor_keyboard_key_code = "mission_control"; }
              ];
            }
          ];
        })
      ];
    };
  };
}

