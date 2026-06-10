function prompt_pwd
    set pwd (pwd)
    string replace -r "^$HOME" "~" $pwd
end
