require "open-uri"

class Recipe < ApplicationRecord
  after_save if: -> { saved_change_to_name? || saved_change_to_ingredients? } do
    set_content
    set_photo
  end
  has_one_attached :photo


  # def content
  #   Rails.cache.fetch("#{cache_key_with_version}/content") do
  #     client = OpenAI::Client.new
  #     chaptgpt_response = client.chat(parameters: {
  #     model: "gpt-3.5-turbo",
  #     messages: [{ role: "user", content: "Give me a simple recipe for #{name} with the ingredients #{ingredients}. Give me only the text of the recipe, without any of your own answer like 'Here is a simple recipe'."}]
  #     })
  #     chaptgpt_response["choices"][0]["message"]["content"]
  #   end
  # end


  def content
    #if the previous behaviour returns blank? do the API call else use the
    #previous behaviour
    if super.blank?
      set_content
    else
      super
    end
  end


  def set_content
    client = OpenAI::Client.new
    chaptgpt_response = client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: "Give me a simple recipe for #{name} with the ingredients #{ingredients}. Give me only the text of the recipe, without any of your own answer like 'Here is a simple recipe'."}]
    })
    new_content = chaptgpt_response["choices"][0]["message"]["content"]
    #generate content from OpenAI

    update(content: new_content)
    #recipe.update(content: new_content)
    return new_content
  end

  private

  def set_photo
    client = OpenAI::Client.new
    response = client.images.generate(parameters: {
      prompt: "A recipe image of #{name}", size: "256x256"
    })

    url = response["data"][0]["url"]
    file =  URI.open(url)

    photo.purge if photo.attached?
    photo.attach(io: file, filename: "ai_generated_image.jpg", content_type: "image/png")
    return photo
  end
end
