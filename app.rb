require 'sinatra'
require 'slim'
require 'BCrypt'
require 'SQLite3'

enable :sessions

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end


get('/') do
    slim(:start)
end


get('/users/register') do
    slim(:"users/register")
end


post('/create') do
    db = connect_to_db("db/databas.db")
    username = params["username"]
    password = params["password"]
    confirm_password = params["confirm_password"]
    behorighet = 1
    result = db.execute("SELECT * FROM Users WHERE username=?", username)

    if result.empty?
        if password == confirm_password
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO Users(username, Password, behorighet) VALUES (?,?,?)", [username, password_digest, behorighet])
            session[:user_id] = db.execute("SELECT user_id FROM Users WHERE username=?", [username])
            session[:username] = username
            redirect('/register_confirmation')
        else
            redirect('/error_not_same_password')
            
        end
    else
        redirect('/error_same_username')
    end

    redirect('/users/index')
end


get('/register_confirmation') do
    slim(:register_confirmation)
end


get('/users/login') do
    slim(:"users/login")
end

get('/lists/index') do
    docs = []
    slim(:"lists/index", locals:{docs:docs})
end

post('/login') do
    db = connect_to_db("db/databas.db")
    username = params["username"]
    password = params["password"]
    db.results_as_hash = true
    result = db.execute("SELECT user_id, password FROM Users WHERE username=?", [username])
    if result.empty?
        redirect('/error_login')
    end
    user_id = result.first["user_id"]
    password_digest = result.first["password"]
    if BCrypt::Password.new(password_digest) == password
        session[:username] = username
        session[:user_id] = user_id
        redirect("/lists/index")
    end
    
end


get('/lists/create') do
    db = connect_to_db("db/databas.db")
    db.results_as_hash = true
    todo = db.execute('SELECT * FROM Doc WHERE doc_id=?', session[:user_id])
    slim(:"lists/index", locals:{docs:docs})
end


post('/lists/create_list') do
    db = connect_to_db("db/databas.db")
    title = params["title"]
    if title == ""
        redirect('/lists/index')
    end
    db.execute("INSERT INTO Doc(doc_name, doc_id) VALUES (?,?)", [title, session[:user_id]])
    redirect('/lists/index')
end


post('/lists/:id/update') do
    db = connect_to_db("db/databas.db")
    update=params["update"]
    list_id = params[:id].to_i
    db.execute('UPDATE Doc SET doc_name = ? WHERE ID=? ', update, list_id)
    redirect('/lists/index')
end


post('/lists/:id/delete') do
    db = connect_to_db("db/databas.db")
    list_id = params[:id].to_i
    db.execute('DELETE FROM Doc WHERE doc_id=? ', list_id)
    redirect('/lists/index')
end


get('/error') do
    slim(:error)
end

get('/error_same_username') do
    slim(:error_same_username)
end

get('/error_not_same_password') do
    slim(:error_not_same_password)
end

get('/error_login') do
    slim(:error_login)
end