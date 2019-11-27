# Fish

As noted other places in this repository I use [fish shell](https://fishshell.com/) in my local environment. After 15 years of using Bash and Zsh I found fish to be very good. While I still write my shell scripts in Bash I find fish to be good at living in a CLI life. [Here's a good read](https://medium.com/better-programming/why-i-use-fish-shell-over-bash-and-zsh-407d23293839) if you are interested in making the switch.

Some useful resources:

- Package manager for the fish shell: [fisher](https://github.com/jorgebucaran/fisher) or [oh-my-fish](https://github.com/oh-my-fish/oh-my-fish)
- [kubectl completions for fish shell](https://github.com/evanlucas/fish-kubectl-completions)
- [Git plugin for fish shell](https://github.com/jhillyerd/plugin-git) can be installed with fisher `fisher add jhillyerd/plugin-git`
- Meta: [A curated list of packages, prompts, and resources for the fish shell.](https://github.com/jorgebucaran/awesome-fish)

Some of my favorite aliases or functions:

```bash
# Alias k to kubectl
function k --wraps kubectl -d 'kubectl shorthand'
    kubectl $argv
end

# Save the function
funcsave k
```
