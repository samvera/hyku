## Adding a New Custom Theme
Developers can add new home page themes and show page themes to an application with four steps:
* Add the basic theme information
* Add any view/template overrides
* Add the custom CSS for the theme
* Add a wireframe to render on the theme select page

### Adding theme information
Basic theme information for home page themes is added to `config/home_themes.yml` and theme information for the show page themes is added to `config/show_themes.yml`.

Example code (for a theme named "Magnificent"): 
```
magnificent:
  banner_image: true
  featured_researcher: true
  home_page_text: false
  marketing_text: true
  name: Magnificent
  notes: This theme is recommended for institutional repositories and is designed to highlight a featured researcher.
```

### Adding view/template overrides
Your theme will probably require changes to the default Hyku templates. Hyku will look for your theme templates in a specific location.  Any template overrides should be placed inside a folder that shares your theme name (magnificent, in this example). For example, if you are overriding the `_home_content.html.erb` template, you should place your version in `app/views/themes/magnificent/hyrax/homepage/_home_content.html.erb`.

The more complex your theme is, the more likely you will have several template overrides.

### Adding custom CSS
Your theme will probably require custom CSS. Hyku will look for your theme CSS file in a specific location, and it expects the name of the file to match your theme name (magnificent, in this example). Your theme stylesheet should be a .SCSS file and should be located at `app/assets/stylesheets/themes/magnificent.scss.`

Your stylesheet needs to wrap all of your theme styles inside of a class that shares your theme name. Hyku will add a class with your theme name to the body tag, so this will ensure that your theme styles will only apply when your theme is active.

For example:
```
.magnificent {
  img {
    border-radius: 50%;
    border: .5px solid #ccc;
    padding: 5px;
  }
}
```

### Theme wireframe
Your theme requires a wireframe so that users can see a preview of what your theme will look like when selecting it in the Admin Dashboard Appearance panel.

Your wireframe should be added to the asset pipeline, inside of a folder named after your theme. Your wireframe must be a .jpg file, and it must be named after your theme. For example, if your theme name is "Magnificent", you would place your wireframe at `app/assets/images/themes/magnificent/magnificent.jpg`.


