// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/carbon_cop_check_app_web.ex",
    "../lib/carbon_cop_check_app_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        // Carbon Copy Brand Colors
        'cc-orange': {
          DEFAULT: '#E8692C',
          light: '#F4A574',
          dark: '#C94E14',
        },
        'cc-blue': {
          DEFAULT: '#2B7CBF',
          light: '#5BA3D9',
          dark: '#1A5A8F',
        },
        'cc-green': {
          DEFAULT: '#2D7D4E',
          light: '#4CA66D',
          dark: '#1E5635',
        },
        'cc-gold': {
          DEFAULT: '#D4A84B',
          light: '#E8C97A',
          dark: '#B08930',
        },
        'cc-cream': {
          DEFAULT: '#FDF6E3',
          dark: '#F5E6C8',
        },
        'cc-brown': {
          DEFAULT: '#3D2914',
          light: '#5C3D1E',
        },
        // Semantic colors
        'brand': '#E8692C',
      },
      fontFamily: {
        'script': ['Lobster', 'cursive'],
        'display': ['Bebas Neue', 'sans-serif'],
        'body': ['Source Sans 3', 'sans-serif'],
      },
      boxShadow: {
        'tattoo': '3px 3px 0 rgba(61, 41, 20, 0.8)',
        'tattoo-sm': '2px 2px 0 rgba(61, 41, 20, 0.8)',
        'tattoo-lg': '4px 4px 0 rgba(61, 41, 20, 0.8)',
      },
      borderWidth: {
        '3': '3px',
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, {values})
    })
  ]
}
