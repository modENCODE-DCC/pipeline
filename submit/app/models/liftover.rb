class Liftover < Command
  module Status
    LIFTING = "lifting"
    LIFTED = "lifted over"
    LIFTOVER_FAILED = "liftover failed"
  end

 # def status=(newstatus)
 #   write_attribute :status, newstatus
 #   # Overriding Command's status= so that the project's status isn't also updated
 # end
end
