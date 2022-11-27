# Green and red depending on exit status.

function fish_prompt
  if [ $status = 0 ] 
    set_color green
  else
    set_color red
  end

  echo -n '≫'

  set_color normal
  echo -n ' '
end
