nest = include 'lib/nest/core'
Key, Enc = include 'lib/nest/norns'
Text = include 'lib/nest/text'
Grid = include 'lib/nest/grid'
of = include 'lib/nest/util/of'

local preset_count = 8

tune, Tune = include 'lib/tune/tune' 
tune.setup { presets = preset_count, scales = include 'lib/tune/scales' }

params:add_separator('tuning')

local function clear()
    --n.keyboard:clear()
    engine.stopAll()
end

params:add {
    type='option', id='voicing', options={ 'poly', 'mono' },
    action = clear,
}

params:add {
    type='number', name='scale preset', id='scale_preset', min = 1, max = preset_count,
    default = 1, action = function()
        nest.screen.make_dirty()
    end
}
params:add {
    type='number', name='transpose', id='transpose', min = 0, max = 7,
    default = 0,
}
params:add {
    type='number', name='octave', id='octave', min = -3, max = 4,
    default = 0,
}

local App = {}

function App.grid()
    local _keymap = Grid.momentary()

    local _scale_preset = Grid.number()

    local _scale_degrees = Tune.grid.scale_degrees({ left = 9, top = 2 })
    local _tonic = Tune.grid.tonic({ left = 9, top = 5 })

    local _transpose = Grid.number()
    local _octave = Grid.number()

    return function()
        _keymap{
            x = { 1, 8 }, y = { 1, 8 },
            lvl = function(_, x, y)
                return 
                    tune.is_tonic(x, y, params:get('scale_preset'), params:get('transpose')) 
                    and { 4, 15 } or { 0, 15 }
            end,
            action = function(v, t, d, add, rem)
                local k = add or rem
                local id = params:get('voicing') == 2  and 0 or k.x + (k.y * 16)

                local trans, oct, pre = params:get('transpose'), params:get('octave'), params:get('scale_preset')

                local hz = 440 * tune.hz(k.x, k.y, trans, oct, pre)
                local midi = tune.midi(k.x, k.y, trans, oct, pre)

                if add then
                    engine.start(id, hz)
                    if midi then m:note_on(midi, vel or 1, 1) end
                elseif rem then
                    engine.stop(id) 
                    if midi then m:note_off(midi, vel or 1, 1) end
                end
            end
        }

        _scale_preset{
            x = { 9, 16 }, y = 1,
            state = of.param('scale_preset')
        }

        _scale_degrees{ preset = params:get('scale_preset') }
        _tonic{ preset = params:get('scale_preset') }

        _transpose{
            x = { 9, 16 },
            y = 7,
            lvl = function(_, x) 
                local iv = tune.get_intervals(params:get('scale_preset'))
                local x = tune.wrap(x, 0, params:get('scale_preset'))
                return (
                    (iv[x] == 7 or iv[x] == 0)
                ) and { 4, 15 } or { 0, 15 }
            end,
            state = of.param('transpose')
        }
        _octave{
            x = { 9, 16 },
            y = 8,
            state = of.param('octave')
        }
    end
end

function App.norns()
    local _scale_degrees = Tune.norns.scale_degrees()
    local _options = Tune.norns.options()

    return function()
        _scale_degrees{ preset = params:get('scale_preset') }
        _options{ preset = params:get('scale_preset') }
    end
end

local _app = {
    grid = App.grid(),
    norns = App.norns()
}

nest.connect_grid(_app.grid, grid.connect())
nest.connect_enc(_app.norns)
nest.connect_key(_app.norns)
nest.connect_screen(_app.norns)

params:add_separator()
engine.name = 'PolySub'
polysub = require 'polysub'
polysub.params()

function init()
    params:bang()
end
