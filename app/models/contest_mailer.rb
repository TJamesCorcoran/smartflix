class ContestMailer < ActionMailer::Base

  def contest_ping(contest, email)
    subject     case contest.phase
                when Contest::VOTING_PHASE
                  "Voting has begun for #{contest.title}!"
                when Contest::ARCHIVE_PHASE
                  "Results are in for #{contest.title}!"
                end
    recipients  Rails.env == 'production' ?  email : EMAIL_TO_DEVELOPER
    from        EMAIL_FROM
    body        :phase       => contest.phase,
                :title       => contest.title,
                :contest_url => url_for(:host       => SmartFlix::Application::WEB_SERVER,
                                        :controller => "contest",
                                        :action     => "show",
                                        :id         => contest.id)
  end
end
