<html>
<body>
  <h1>ApiDump</h1> v1.0.0.4
  Last updated on 2019-04-26<br/><br/>
  
  This is a simple API output generator that generates API documentation along with 
  usage examples and response output based on API specification.<br/><br/>
  
  Usage:<br/>
  <pre>ruby apidump.rb myapi.apispec [myapi.html]</pre>
  <br/><br/>
  
  Example of simple apispec file:<br/>
  <pre>
ApiDump::Specification.new do |s|
  s.title         = "API Documentation for My Simple App"
  s.version       = "1.0.0.0"
  s.date          = "190426"
  s.base_url      = "http://localhost:4567"
  s.output_format = "HTML"
  s.header        = "&lt;br/&gt;&lt;br/&gt;Example of documentation header&lt;br/&gt;&lt;br/&gt;"
  
  s.features = 
    [
      {
        name: "Users.Login", 
        description: 
          "Log a user into the system. After successful login, system return a " \
          "uniquely generated token to be used to access all API's functions.", 
        method: "POST", 
        request_type: "JSON", 
        url: "/users/login", 
        params: 
          {
            values: 
              {
                login: "User ID, string, mandatory", 
                password: "Password, string, mandatory"
              }, 
            title: "All parameters are mandatory."
          }, 
        examples: 
          [
            {
              id: :login1, 
              title: "Login using wrong user ID", 
              url: "/users/login", 
              params: {login: "invalid_user", password: "invalid_password"}
            }, 
            {
              id: :login2, 
              title: "Login using wrong password", 
              url: "/users/login", 
              params: {login: "superadmin", password: "superduper"}
            }, 
            {
              id: :login3, 
              title: "Login as Admin", 
              url: "/users/login", 
              params: {login: "admin", password: "admin"}, 
              output: {token: "data/token"}
            }
          ]
      }, 
      {
        name: "Users.List", 
        description: "Get list of available users", 
        method: "POST", 
        request_type: "JSON", 
        url: "/users", 
        params: 
          {
            values: 
              {
                token: "Login token, string, mandatory", 
                user_id: "User ID, integer, optional", 
                department_id: "Department ID, integer, optional", 
                division_id: "Division ID, integer, optional", 
                section_id: "Section ID, integer, optional", 
                occupation_id: "Occupation ID, integer, optional", 
                user_type_id: "User type ID, integer, optional"
              }
          }, 
        examples: 
          [
            {
              id: :users, 
              title: "Get list of available users", 
              url: "/users", 
              params: {limit: 10}, 
              input: {token: ":login3/:token"}
            }
          ]
      }
    ]
end
  </pre>
  
  For example, check *.apispec and *.html output.
</body>
</html>
